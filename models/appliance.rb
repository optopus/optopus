class Appliance < ActiveRecord::Base
  include AttributesToLiquidMethodsMapper

  validates :serial_number, :primary_mac_address, :presence => true
  before_create :assign_uuid

  private

  def assign_uuid
    self.uuid = UUIDTools::UUID.md5_create(UUIDTools::UUID_DNS_NAMESPACE, "#{self.serial_number.downcase} #{self.primary_mac_address.downcase}").to_s
  end
end
