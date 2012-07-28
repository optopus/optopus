module Optopus
  class Location < ActiveRecord::Base

    validates :common_name, :city, :state, :presence => true
    validates_uniqueness_of :common_name

    has_many :devices

    def nodes
      Optopus::Node.where("facts -> 'location' = '#{self.common_name}'")
    end
  end
end
