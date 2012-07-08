module Optopus
  class Appliance < ActiveRecord::Base
    include AttributesToLiquidMethodsMapper

    validates :serial_number, :primary_mac_address, :uuid, :location, :presence => true
    validates_uniqueness_of :uuid
    validates_associated :location
    before_validation :assign_uuid

    has_many :nodes
    belongs_to :location

    private

    def assign_uuid
      unless self.serial_number.nil? or self.primary_mac_address.nil?
        self.uuid = "#{self.serial_number.downcase} #{self.primary_mac_address.downcase}".to_md5_uuid
      end
    end
  end
end
