require 'singleton'

module Optopus

  def self.base_menus
    return @base_menus if @base_menus
    @base_menus = []
    bare_metal_menu = Optopus::NavLink.new(:display => 'Bare Metal', :route => '/bare_metal', :id => :bare_metal)
    nodes_menu = Optopus::NavLink.new(:display => 'Nodes', :route => '/nodes', :id => :nodes)
    networks_menu = Optopus::NavLink.new(:display => 'Networks', :route => '/networks', :id => :networks)
    reports_menu = Optopus::NavLink.new(:display => 'Reports', :route => '/routes', :id => :reports)
    events_menu = Optopus::NavLink.new(:display => 'Events', :route => '/events', :id => :events)

    # This should really be moved to plugins, but at the moment
    # it is a hardcoded list.
    events_menu.type = 'dropdown'
    events_submenu = Optopus::Menu::Section.new(:name => 'event_types')
    events_submenu.add_link(:display => 'Network Events', :href => '/events/network')
    events_submenu.add_link(:display => 'Provision Events', :href => '/events/provision')
    events_submenu.add_link(:display => 'Deployment Events', :href => '/events/deploy')
    events_submenu.add_link(:display => 'All Events', :href => '/events')
    events_menu.sections << events_submenu

    @base_menus << bare_metal_menu
    @base_menus << nodes_menu
    @base_menus << networks_menu
    @base_menus << reports_menu
    @base_menus << events_menu
    @base_menus
  end

  def self.get_base_menu(id)
    base_menus.find { |m| m.options[:id] == id }
  end

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
    attr_accessor :display, :route, :type, :required_role, :options

    def initialize(options={})
      @display = options.delete(:display)
      @route = options.delete(:route)
      @required_role = options.delete(:required_role)
      @type = options.delete(:type) || 'simple'
      @options = options
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
          html << "<li><a href=\"#{link[:href]}\" onclick=\"#{link[:onclick]}\">#{link[:display]}</a></li>"
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
