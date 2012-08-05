module Optopus
  class Device < ActiveRecord::Base
    include Tire::Model::Search
    include Tire::Model::Callbacks
    include AttributesToLiquidMethodsMapper

    validates :serial_number, :primary_mac_address, :location, :presence => true
    validates_uniqueness_of :primary_mac_address
    validates_associated :location
    before_validation :downcase_primary_mac_address
    before_save :check_provisioned_status

    has_many :nodes
    belongs_to :location

    mapping do
      indexes :id,          :index => :not_analyzed
      indexes :macaddress,  :as => 'primary_mac_address', :boost => 10
      indexes :serial_number
    end

    private

    def downcase_primary_mac_address
      self.primary_mac_address = self.primary_mac_address.downcase unless self.primary_mac_address.nil?
    end

    def check_provisioned_status
      provisioned = nodes.empty? ? false : true
      nil
    end
  end
end
