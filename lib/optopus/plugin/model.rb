module Optopus
  module Plugin
    class Model < ActiveRecord::Base
      self.abstract_class = true
      self.table_name_prefix = 'plugin_'
      def self.table_name
        "#{self.table_name_prefix}#{undecorated_table_name}"
      end

      def self.plugin
        unless plugin = Optopus::Plugins.find_plugin_for_model(self)
          raise "Could not find the plugin that created #{self} model!"
        end
        plugin
      end

      def self.plugin_name
        plugin.to_s.demodulize.underscore
      end

      # So that we can attempt to determine the plugin from
      # which this new module came, we store the caller information
      def self.caller_path
        @caller_path
      end

      def self.caller_path=(value)
        @caller_path = value
      end

      def self.inherited(subclass)
        super
        subclass.caller_path = File.dirname(caller[0])
        subclass.caller_path
        Optopus::Models.register_model(subclass)
      end
    end
  end
end
