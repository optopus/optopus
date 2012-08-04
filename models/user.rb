module Optopus
  class User < ActiveRecord::Base
    validates :username, :display_name, :presence => true
    validates_uniqueness_of :username
    serialize :properties, ActiveRecord::Coders::Hstore
    has_and_belongs_to_many :roles

    def member_of?(role_id)
      roles.where(:id => role_id).first != nil
    end
  end
end
