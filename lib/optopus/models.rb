module Optopus
  module Models
    def self.mixins
      @mixins ||= Hash.new
    end

    def self.model_data
      @model_data ||= Hash.new
    end

    # expects string form name of model and mixin constants
    # this is later used to dynamically add mixins to our models
    def self.register_mixin(model, mixin)
      mixins[model] ||= Array.new
      mixins[model] << mixin
    end

    # since models are loaded after plugins, we must store any 
    # model data that should exist here, which models will read from
    # to populate specific tables. values is expected to be a hash
    # ex: ensure_exists('Optopus::Role', :name => 'teams_admin')
    def self.ensure_exists(model, values)
      model_data[model] ||= Array.new
      model_data[model] << values
    end

    # return only the model that matches the passed in type
    def self.type(type)
      list.each do |model|
        return model if model.to_s.demodulize.underscore == type
      end
    end

    def self.list
      @models ||= []
    end

    def self.register_model(name)
      list << name
    end
  end
end
