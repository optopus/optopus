module Optopus
  class Role < ActiveRecord::Base
    include AttributesToLiquidMethodsMapper
    validates :name, :presence => true
    validates_uniqueness_of :name
    serialize :properties, ActiveRecord::Coders::Hstore
    has_and_belongs_to_many :users
  end
end
