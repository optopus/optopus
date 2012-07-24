module Optopus
  class User < ActiveRecord::Base
    validates :username, :display_name, :presence => true
    serialize :properties, ActiveRecord::Coders::Hstore
  end
end
