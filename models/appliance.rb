class Appliance < ActiveRecord::Base
  include AttributesToLiquidMethodsMapper

  validates :serial_number, :primary_mac_address, :uuid, :presence => true
  validates_uniqueness_of :uuid
  before_validation :assign_uuid

  private

  def assign_uuid
    unless self.serial_number.nil? or self.primary_mac_address.nil?
      self.uuid = UUIDTools::UUID.md5_create(UUIDTools::UUID_DNS_NAMESPACE, "#{self.serial_number.downcase} #{self.primary_mac_address.downcase}").to_s
    end
  end
end
