module Optopus
  class User < ActiveRecord::Base
    validates :username, :display_name, :presence => true
    validates_uniqueness_of :username
    serialize :properties, ActiveRecord::Coders::Hstore
  end
end
