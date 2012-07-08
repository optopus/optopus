module Optopus
  class Node < ActiveRecord::Base
    include AttributesToLiquidMethodsMapper

    validates :uuid, :hostname, :serial_number, :primary_mac_address, :presence => true
    validates_uniqueness_of :uuid
    before_validation :assign_uuid
    belongs_to :appliance

    private

    def assign_uuid
      unless self.serial_number.nil? or self.primary_mac_address.nil?
        self.uuid = "#{self.serial_number.downcase} #{self.primary_mac_address.downcase}".to_md5_uuid
      end
    end
  end
end
