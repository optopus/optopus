require 'backports/basic_object' unless defined? BasicObject

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
      base.set :load_views, true
    end

    def plugin(&block)
      yield
    end

    def set(key, value)
      plugin_settings[key] = value
    end

    def plugin_settings
      @plugin_settings ||= Hash.new
    end

    def registered(app = nil, &block)
      @app = app
      load_views if plugin_settings[:load_views]
      app ? replay(app) : record(:class_eval, &block)
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

    def load_views
      views_path = File.join(plugin_settings[:plugin_path], plugin_settings[:root], 'views')
      Dir.glob("#{views_path}/*.erb") do |erb_file|
        template_name = File.basename(erb_file).gsub('.erb', '')
        @app.template template_name do
          File.read(erb_file)
        end
      end
    end

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
