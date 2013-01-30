require 'singleton'

module Optopus
  class BaseMenu
    include Singleton
    def register_section(section)
      sections << section
    end

    def sections
      @sections ||= Array.new
    end
  end

  class ProfileMenu < BaseMenu ; end
  class UtilityMenu < BaseMenu ; end
  class Menu < BaseMenu ; end

  class Menu::Section
    attr_accessor :name, :required_role
    def initialize(options={})
      @name = options.delete(:name)
      @required_role = options.delete(:required_role)
      @options = options
    end

    def add_link(link={})
      raise 'Missing display option' unless link.include?(:display)
      raise 'Missing href option' unless link.include?(:href)
      links << link
    end

    def links
      @links ||= Array.new
    end
  end

end
