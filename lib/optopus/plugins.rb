require 'yaml'

module Optopus
  module Plugins
    # Create an array of possible paths that should contain plugins. This starts
    # checks for an environment variable PLUGIN_PATHS which may contain multiple
    # paths separated by ':'. Example:
    #
    #   PLUGIN_PATHS="/tmp/plugin_path1:/tmp/plugin_path2"
    #
    # It then checks if we set a plugins_path in the settings file.
    def self.paths
      # In order for this to properly work inside of our Gemfile, we cannot use
      # any code from Sinatra or other gems.
      paths = Array.new
      case defined?(Optopus::App)
      when true
        paths << File.join(File.expand_path(Optopus::App.root), 'plugins')
        if Optopus::App.settings.respond_to?(:plugins_path)
          paths << Optopus::App.settings.plugins_path
        end
      else
        # This mimics what Sinatra does for loading our config file and
        # determining the current environment. It's a big hairy since we could
        # theoretically have drastically different paths array based on whether
        # or not you have included Optopus::App.
        paths << File.join(Dir.pwd, 'plugins')
        config_file = ENV['OPTOPUS_CONFIG_FILE'] || File.join(Dir.pwd, 'config', 'application.yaml')
        environment = ENV['RACK_ENV'] || 'development'
        if File.exists?(config_file)
          settings = YAML.load_file(config_file)[environment]
          if settings.include?('plugins_path')
            paths << settings['plugins_path']
          end
        end
      end
      if ENV['PLUGIN_PATHS']
        paths += ENV['PLUGIN_PATHS'].split(':')
      end
      paths
    end

    def self.list
      @plugins ||= []
    end

    # Only list plugins that have been registered
    def self.list_registered
      list.select { |p| Optopus::App.extensions.include?(p) }
    end

    def self.register_plugin(name)
      list << name
    end

    # Attempt to find out which plugin created the supplied model
    def self.find_plugin_for_model(model)
      list.each do |plugin|
        if model.caller_path.include?(plugin.plugin_settings[:plugin_path])
          return plugin
        end
      end
      nil
    end

    def self.registered(app)
      app.set :plugin_navigation, Array.new
      app.set :optopus_plugins, Array.new
      app.set :partials, { :node => Array.new }
      paths.each do |path|
        Dir.glob("#{path}/*/init.rb").each do |plugin|
          require plugin
        end
      end

      Optopus::Plugin.constants.each do |const|
        next if const.to_s == 'DontCall'
        next if const.to_s == 'Model'
        # Only load a plugin if we have a configuration for it
        config_key = const.to_s.demodulize.underscore
        if app.settings.respond_to?(:plugins) && app.settings.plugins.include?(config_key)
          puts "Loading plugin: #{const}"
          plugin = Optopus::Plugin.const_get(const)
          Optopus::Models.called_from_plugin(plugin).each do |model|
            model.table_name_prefix = "plugin_#{model.plugin_name}_"
          end
          app.register plugin
        end
      end
    end
  end
end
