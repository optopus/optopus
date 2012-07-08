module Optopus
  class Location < ActiveRecord::Base
    include AttributesToLiquidMethodsMapper

    validates :common_name, :presence => true
    validates_uniqueness_of :common_name

    has_many :appliances
  end
end
