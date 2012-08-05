module Optopus
  module Plugin
    class Model < ActiveRecord::Base
      self.abstract_class = true
      self.table_name_prefix = 'plugin_'
      def self.table_name
        "#{self.table_name_prefix}#{undecorated_table_name}"
      end

      def self.inherited(subclass)
        Optopus.register_model(subclass)
      end
    end
  end
end
