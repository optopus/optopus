module Optopus
  module Menu
    def self.register_section(section)
      sections << section
    end

    def self.sections
      @sections ||= Array.new
    end

    class Section
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

end
