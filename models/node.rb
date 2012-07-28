module Optopus
  class Node < ActiveRecord::Base
    include Tire::Model::Search
    include Tire::Model::Callbacks

    validates :uuid, :hostname, :serial_number, :primary_mac_address, :presence => true
    validates :virtual, :inclusion => { :in => [true, false] }
    validates_uniqueness_of :uuid
    before_validation :assign_uuid
    before_save :assign_appliance
    belongs_to :appliance

    serialize :facts, ActiveRecord::Coders::Hstore

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
        indexes :uuid,        :boost => 0
        indexes :facts
      end
    end

    def facts
      # if a node has no facts set, we get nil back which is problematic, so lets return an empty hash in that case
      read_attribute(:facts) || Hash.new
    end

    private

    def assign_uuid
      unless self.serial_number.nil? or self.primary_mac_address.nil?
        self.uuid = "#{self.serial_number.downcase} #{self.primary_mac_address.downcase}".to_md5_uuid
      end
    end

    def assign_appliance
      if self.virtual
        # TODO: determine best way to associate an appliance with virtual nodes
      else
        self.appliance = Appliance.where(:uuid => self.uuid).first
        unless self.facts.nil?
          if self.appliance.nil?
            # auto generate an appliance record, since we probably want to know what physical hardware we have
            serial_number = self.facts['serialnumber']
            primary_mac_address = self.facts['macaddress']
            location = Location.where(:common_name => self.facts['location']).first
            if serial_number && primary_mac_address && location
              self.appliance = Appliance.new(:serial_number => serial_number, :primary_mac_address => primary_mac_address)
              self.appliance.location = location
              self.appliance.brand = self.facts['boardmanufacturer']
              self.appliance.model = self.facts['productname']
              self.appliance.save!
            end
          else
            unless self.appliance.provisioned
              self.appliance.provisioned = true
            end
            if self.facts['boardmanufacturer'] && self.facts['productname']
              self.appliance.brand = self.facts['boardmanufacturer']
              self.appliance.model = self.facts['productname']
            end
            self.appliance.save!
          end
        end
      end
    end
  end
end
