module Optopus
  class Device < Optopus::Model
    include Tire::Model::Search
    include Tire::Model::Callbacks
    include AttributesToLiquidMethodsMapper

    validates :serial_number, :primary_mac_address, :location, :presence => true
    validates_uniqueness_of :primary_mac_address
    validates_associated :location
    before_validation :normalize_attributes
    before_save :check_provisioned_status
    after_create :register_create_event

    has_many :nodes
    belongs_to :location

    serialize :properties, ActiveRecord::Coders::Hstore

    set_search_options :default_operator => 'AND', :fields => [:serial_number, :macaddress]
    set_highlight_fields :serial_number, :macaddress
    set_search_display_key :serial_number

    mapping do
      indexes :id,          :index => :not_analyzed
      indexes :macaddress,  :as => 'primary_mac_address', :boost => 10
      indexes :updated_at
      indexes :created_at
      indexes :serial_number
    end

    def location_name
      location ? location.common_name : nil
    end

    private

    def register_create_event
      event = Optopus::Event.new
      event.message = "new device <a href=\"/device/{{ references.device.id }}\">{{ references.device.serial_number }}</a> has been created"
      event.type = 'device_created'
      event.properties['device_id'] = id
      event.save!
    end

    def normalize_attributes
      self.primary_mac_address = self.primary_mac_address.downcase.strip unless self.primary_mac_address.nil?
      self.serial_number = self.serial_number.downcase.strip unless self.serial_number.nil?
    end

    def check_provisioned_status
      provisioned = nodes.empty? ? false : true
      nil
    end
  end
end
