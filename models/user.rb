require 'gravtastic'

module Optopus
  class User < Optopus::Model
    include AttributesToLiquidMethodsMapper
    include Gravtastic
    is_gravtastic
    validates :username, :display_name, :presence => true
    validates_uniqueness_of :username
    serialize :properties, ActiveRecord::Coders::Hstore
    has_and_belongs_to_many :roles
    liquid_methods :to_link
    before_save :sanitize_data

    def to_link
      "<a href=\"/user/#{username}\">#{display_name}</a>"
    end

    def to_h
      { :username => username, :display_name => display_name }
    end

    def email
      properties['email']
    end

    def events
      Optopus::Event.where("properties -> 'user_id' = '#{id}' or properties -> 'user_username' = '#{username}'").order('created_at DESC')
    end

    def latest_events(latest=10)
      events.limit(latest)
    end

    def member_of?(role_id)
      roles.where(:id => role_id).first != nil
    end

    private

    def sanitize_data
      self.display_name = clean_text(display_name)
    end
  end
end
