module Optopus
  module Plugins
    def self.registered(app)
      app.set :plugin_navigation, Array.new
      app.set :optopus_plugins, Array.new
      app.set :partials, { :node => Array.new }
      plugin_paths = [ File.expand_path(File.dirname(app.root), 'plugins') ]
      plugin_paths << app.settings.plugin_paths if app.settings.respond_to?(:plugin_paths)
      plugin_paths.each do |path|
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
