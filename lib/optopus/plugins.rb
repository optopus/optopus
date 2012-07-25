module Optopus
  module Plugins
    def self.registered(app)
      plugin_paths = [ File.expand_path(File.dirname(app.root), 'plugins') ]
      plugin_paths << app.settings.plugin_paths if app.settings.respond_to?(:plugin_paths)
      plugin_paths.each do |path|
        Dir.glob("#{path}/*.rb").each do |plugin|
          require plugin
        end
      end

      Optopus::Plugin.constants.each do |const|
        next if const == 'DontCall'
        puts "Loading plugin: #{const}"
        app.register Optopus::Plugin.const_get(const)
      end
    end
  end
end
