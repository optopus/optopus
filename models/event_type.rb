module Optopus
  class EventType < ActiveRecord::Base
    include AttributesToLiquidMethodsMapper
    has_many :events
    validates :name, :presence => true
    validates_uniqueness_of :name
    serialize :properties, ActiveRecord::Coders::Hstore
  end
end
