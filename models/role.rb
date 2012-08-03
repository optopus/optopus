module Optopus
  class Role < ActiveRecord::Base
    validates :name, :presence => true
    validates_uniqueness_of :name
    serialize :properties, ActiveRecord::Coders::Hstore
  end
end
