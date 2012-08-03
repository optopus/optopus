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
        app.settings.partials[:node] += plugin_settings[:partials][:node] if plugin_settings[:partials].include?(:node)
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
