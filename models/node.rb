module Optopus
  class Node < Optopus::Model
    include Tire::Model::Search
    include Tire::Model::Callbacks
    include AttributesToLiquidMethodsMapper

    validates :hostname, :primary_mac_address, :presence => true
    validates :virtual, :inclusion => { :in => [true, false] }
    validates_uniqueness_of :hostname
    before_validation :downcase_primary_mac_address
    before_save :assign_device
    belongs_to :device
    after_create :register_create_event

    serialize :facts, ActiveRecord::Coders::Hstore
    serialize :properties, ActiveRecord::Coders::Hstore
    liquid_methods :to_link

    settings :analysis => {
        :analyzer => {
          :hostname => {
            "tokenizer"    => "lowercase",
            "pattern"      => "(\\W)(?=\\w)|(?<=\\w)(?=\\W)|(?<=\\D)(?=\\d)|(?<=\\d)(?=\\D)",
            "type"         => "pattern" }
        }
      } do
      mapping do
        indexes :id,          :index => :not_analyzed
        indexes :hostname,    :boost => 100, :analyzer => 'hostname'
        indexes :macaddress,  :as => 'primary_mac_address', :boost => 10
        indexes :ipaddress,   :as => "facts['ipaddress']", :boost => 10
        indexes :switch,      :as => "facts['lldp_em1_chassis_name']", :boost => 10 # TODO: put this in the lldp plugin since most default systems wont have the lldp_* facts
        indexes :productname, :as => "facts['productname']", :boost => 10
      end
      indexes :facts,       :boost => 1
    end

    def self.active
      where(:active => true)
    end

    def self.inactive
      where(:active => false)
    end

    def to_link
      "<a href=\"/node/#{id}\">#{hostname}</a>"
    end

    def to_h
      { :hostname => hostname, :virtual => virtual, :primary_mac_address => primary_mac_address }
    end

    # This uses tire search functionality to load up hypervisors
    # that potentially contain this virtual machine.
    def find_hypervisor_host
      return [] unless self.virtual
      Optopus::Hypervisor.search("libvirt.domains.name:\"#{self.hostname}\"", :load => true)
    end

    private

    def register_create_event
      event = Optopus::Event.new
      event.message = "new node {{ references.node.to_link }} has been created"
      event.type = 'node_created'
      event.properties['node_id'] = id
      event.save!
    end

    def downcase_primary_mac_address
      self.primary_mac_address = self.primary_mac_address.downcase unless self.primary_mac_address.nil?
    end

    def assign_device
      if self.virtual
        # TODO: determine best way to associate an device with virtual nodes
      else
        # when we are working with physical nodes, we should associate them with a device
        # we will attempt to do that by checking for matching primary_mac_address and serial_number
        self.device = Device.where(:serial_number => self.serial_number).where(:primary_mac_address => self.primary_mac_address).first

        unless self.facts.nil?
          if self.device.nil?
            # if we are unable to find a suitable device, ensure necessary facts exist and then create a new one
            location_name = self.facts['location']
            location = Location.where(:common_name => location_name).first
            if location.nil? && !location_name.nil?
              # create a new location since obviously it must exist if a node is registering from there
              location = Location.create(:common_name => location_name, :city => 'Unknown', :state => 'Unknown')
            end
            if self.serial_number && self.primary_mac_address && location
              self.device = Device.new(:serial_number => serial_number, :primary_mac_address => primary_mac_address)
              self.device.location = location
              # it's okay if these facts are nil, since the device model does not require valid presence
              self.device.brand = self.facts['boardmanufacturer']
              self.device.model = self.facts['productname']
              self.device.save!
            end
          else
            # make sure if we already found a device, that it is marked as provisioned since registration
            # typically requires a node to have a full OS installation
            self.device.provisioned = true unless self.device.provisioned
            if self.facts['boardmanufacturer'] && self.facts['productname']
              self.device.brand = self.facts['boardmanufacturer']
              self.device.model = self.facts['productname']
            end
            self.device.save!
          end
        end
      end
    end
  end

  # We inherit Optopus::Node, to provide a search interface into libvirt data
  # and allow postgresql lookups against hypervisors
  class Hypervisor < Node

    # Simple class that allows taking libvirt_data['domains']
    # and turning them into usable classes
    class Domain
      attr_reader :autostart, :cpu_count, :id, :name, :state, :vnc_port, :node
      def initialize(data)
        @autostart = data.delete('autostart')
        @cpu_count = data.delete('cpu_count')
        @id        = data.delete('id')
        @memory    = data.delete('memory')
        @name      = data.delete('name')
        @state     = data.delete('state')
        @vnc_port  = data.delete('vnc_port')
        @node      = Optopus::Node.where(:hostname => @name).first unless @name.nil?
      end

      def memory
        # libvirtd mcollective agent stores memory in kilobytes
        "#{@memory.to_i / 1024} MB"
      end

      def to_link
        @node ? @node.to_link : @name
      end
    end

    mapping do
      indexes :libvirt, :as => 'libvirt_data', :type => 'object'
    end

    def self.find_domain(domain)
      search("libvirt.domains.name:\"#{domain}\"")
    end

    def libvirt_data
      begin
        JSON.parse(properties['libvirt_data'])
      rescue Exception => e
        # silently return nil if we fail to parse json
        nil
      end
    end

    # Libvirt data is assumed to be added via custom mcollective agent which has:
    # 'domains' => [
    #   { 'name' => hostname_of_server }
    # ]
    def libvirt_data=(value)
      raise 'libvirt data must be supplied as a hash' unless value.is_a?(Hash)
      properties['libvirt_data'] = value.to_json
    end

    def domains
      return [] unless libvirt_data.include?('domains')
      libvirt_data['domains'].inject([]) do |domains, domain_data|
        domains << Domain.new(domain_data)
      end
    end
  end
end
