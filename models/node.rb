module Optopus
  class Node < ActiveRecord::Base
    include AttributesToLiquidMethodsMapper

    validates :uuid, :hostname, :serial_number, :primary_mac_address, :presence => true
    validates :virtual, :inclusion => { :in => [true, false] }
    validates_uniqueness_of :uuid
    before_validation :assign_uuid
    before_save :assign_appliance
    belongs_to :appliance

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
      end
    end
  end
end
