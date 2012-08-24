module Optopus
  module Plugins
    def self.paths
      paths = File.join(File.expand_path(Optopus::App.root), 'plugins')
      if ENV['PLUGIN_PATHS']
        paths += ':' + ENV['PLUGIN_PATHS']
      end
      paths.split(':')
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
        next if const == 'DontCall'
        # Only load a plugin if we have a configuration for it
        config_key = const.to_s.demodulize.underscore
        if app.settings.respond_to?(:plugins) && app.settings.plugins.include?(config_key)
          puts "Loading plugin: #{const}"
          app.register Optopus::Plugin.const_get(const)
        end
      end
    end
  end
end
