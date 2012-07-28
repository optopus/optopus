module Optopus
  class Device < ActiveRecord::Base
    include Tire::Model::Search
    include Tire::Model::Callbacks

    validates :serial_number, :primary_mac_address, :uuid, :location, :presence => true
    validates_uniqueness_of :uuid
    validates_associated :location
    before_validation :assign_uuid
    before_save :check_provisioned_status

    has_many :nodes
    belongs_to :location

    mapping do
      indexes :id,          :index => :not_analyzed
      indexes :macaddress,  :as => 'primary_mac_address', :boost => 10
      indexes :uuid,        :boost => 0
      indexes :serial_number
    end

    private

    def assign_uuid
      unless self.serial_number.nil? or self.primary_mac_address.nil?
        self.uuid = "#{self.serial_number.downcase} #{self.primary_mac_address.downcase}".to_md5_uuid
      end
      nil
    end

    def check_provisioned_status
      provisioned = nodes.empty? ? false : true
      nil
    end
  end
end