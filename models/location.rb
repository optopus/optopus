module Optopus
  class Location < ActiveRecord::Base

    validates :common_name, :city, :state, :presence => true
    validates_uniqueness_of :common_name

    has_many :appliances
  end
end
