module Optopus
  class Model < ActiveRecord::Base
    self.abstract_class = true
    def self.inherited(subclass)
      # ensure ActiveRecord::Base#inherited runs first
      super


      # register mixins added by plugins
      if register_mixins = Optopus::Models.mixins[subclass.to_s]
        register_mixins.each do |mixin|
          subclass.send(:include, mixin)
        end
      end

      # register this new model so we know about it
      Optopus::Models.register_model(subclass)
    end
  end
end
