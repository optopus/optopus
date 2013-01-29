require 'backports/basic_object' unless defined? BasicObject
require_relative 'plugin/model'

module Optopus
  module Plugin
    def self.new(&block)
      ext = Module.new.extend(self)
      ext.class_eval(&block)
      ext
    end

    def self.extended(base)
      base.set :plugin_path, File.dirname(caller[0])
      base.set :name, base.name
      base.set :root, base.name.split('::').last.downcase
      base.set :views_path, File.join(base.plugin_settings[:plugin_path], 'views')
      Optopus::Plugins.register_plugin(base)
    end

    def plugin(&block)
      yield
    end

    def nav_link(options={})
      if options.include?(:route) && options.include?(:display)
        set :nav_link, options
      else
        raise 'nav_link must contain route and display keys'
      end
    end

    def register_partial(type, partial, options)
      plugin_settings[:partials] ||= Hash.new
      plugin_settings[:partials][type.to_sym] ||= Array.new
      plugin_settings[:partials][type.to_sym] << options.merge({:template => partial})
    end

    # make it easy for plugins to include roles that they need for authorization purposes
    def register_role(name)
      Optopus::Models.ensure_exists('Optopus::Role', :name => name)
    end

    # provide a way to store modules that models should use as mixins
    def register_mixin(model_type, mixin)
      possible_models = {
        :devices   => 'Optopus::Device',
        :events    => 'Optopus::Event',
        :locations => 'Optopus::Location',
        :nodes     => 'Optopus::Node',
        :roles     => 'Optopus::Role',
        :users     => 'Optopus::User',
      }
      model = possible_models[model_type]
      raise "invalid model type, valid types: #{possible_models.keys.join(', ')}" if model.nil?
      Optopus::Models.register_mixin(model, mixin)
    end

    # allow plugins to register new menu sections
    def register_menu(section)
      Optopus::Menu.register_section(section)
    end

    def register_utility_menu(section)
      Optopus::UtilityMenu.register_section(section)
    end

    def set(key, value)
      plugin_settings[key] = value
    end

    def plugin_settings
      @plugin_settings ||= Hash.new
    end

    def registered(app = nil, &block)
      @app = app
      app ? replay(app) : record(:class_eval, &block)
      app.settings.plugin_navigation << plugin_settings.delete(:nav_link) if plugin_settings.include?(:nav_link)
      if plugin_settings.include?(:partials)
        plugin_settings[:partials].keys.each do |type|
          app.settings.partials[type] ||= Array.new
          app.settings.partials[type] += plugin_settings[:partials][type]
        end
      end
      app.settings.optopus_plugins << plugin_settings
    end

    def routes
      @routes ||= Array.new
    end

    def configure(*args, &block)
      record(:configure, *args) { |c| c.instance_exec(c, &block) }
    end

    def get(*args, &block)
      record(:get, *args, &block)
    end

    def post(*args, &block)
      record(:post, *args, &block)
    end

    def delete(*args, &block)
      record(:delete, *args, &block)
    end

    def put(*args, &block)
      record(:put, *args, &block)
    end

    private

    def record(method, *args, &block)
      recorded_methods << [method, args, block]
    end

    def replay(app)
      recorded_methods.each { |m, a, b| app.send(m, *a, &b) }
    end

    def recorded_methods
      @recorded_methods ||= Array.new
    end

    def method_missing(method, *args, &block)
      return super unless Sinatra::Base.respond_to? method
      record(method, *args, &block)
      DontCall.new(method)
    end

    class DontCall < ::BasicObject
      def initialize(method) @method = method end
      def method_missing(*) fail "not supposed to use the result of #{@method}!" end
      def inspect; "#<#{self.class}: #{@method}>" end
    end

  end
end
