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
  class NavMenu < BaseMenu ; end

  class NavLink
    attr_accessor :display, :route, :type, :required_role

    def initialize(options={})
      @display = options.delete(:display)
      @route = options.delete(:route)
      @required_role = options.delete(:required_role)
      @type = options.delete(:type) || 'simple'
    end

    def sections
      @sections ||= Array.new
    end

    def to_html
      case @type
      when 'simple'
        to_html_simple
      when 'dropdown'
        to_html_dropdown
      else
        raise "Invalid NavLink type: #{@type}"
      end
    end

    private

    def to_html_dropdown
      html = []
      html << '  <li class="dropdown">'
      html << "    <a class=\"dropdown-toggle\" data-toggle=\"dropdown\" href=\"#\">#{@display}<b class=\"caret\"></b></a>"
      html << '    <ul class="dropdown-menu">'
      @sections.each do |section|
        section.links.each do |link|
          html << "<li><a href=\"#{link[:href]}\">#{link[:display]}</a></li>"
        end
      end
      html << '    </ul>'
      html << '  </li>'
      html.join("\n")
    end

    def to_html_simple
      "<li id=\"#{html_id(@display)}\"><a href=\"#{@route}\">#{@display}</a></li>"
    end

    def html_id(string)
      string.downcase.gsub(' ', '_')
    end
  end

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
