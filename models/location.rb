module Optopus
  class Location < Optopus::Model
    include AttributesToLiquidMethodsMapper

    validates :common_name, :city, :state, :presence => true
    validates_uniqueness_of :common_name

    has_many :devices
    has_many :networks
    has_many :pods

    def nodes
      Optopus::Node.where("facts -> 'location' = '#{self.common_name}'")
    end
  end
end
