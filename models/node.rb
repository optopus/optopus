module Optopus
  class Node < ActiveRecord::Base
    include Tire::Model::Search
    include Tire::Model::Callbacks

    validates :hostname, :primary_mac_address, :presence => true
    validates :virtual, :inclusion => { :in => [true, false] }
    validates_uniqueness_of :hostname
    before_validation :downcase_primary_mac_address
    before_save :assign_device
    belongs_to :device

    serialize :facts, ActiveRecord::Coders::Hstore
    serialize :properties, ActiveRecord::Coders::Hstore

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

    def facts
      # if a node has no facts set, we get nil back which is problematic, so lets return an empty hash in that case
      read_attribute(:facts) || Hash.new
    end

    private

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
end
