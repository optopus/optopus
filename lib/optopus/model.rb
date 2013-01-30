require 'sanitize'
module Optopus
  class Model < ActiveRecord::Base
    self.abstract_class = true

    def clean_text(text)
      Sanitize.clean(text)
    end

    def self.search_options
      @search_options ||= Hash.new
    end

    def self.highlight_fields
      @highlight_fields
    end

    def self.search_display_key
      @search_display_key ||= :name
    end

    # Allows models to set what search options are used for
    # the model. This only gets used in Optopus::Search
    def self.set_search_options(options)
      @search_options = options
    end

    # Allows models to set what search fields to return highlight
    # data on. This only gets used in Optopus::Search
    def self.set_highlight_fields(*args)
      @highlight_fields = args
    end

    # Allows models to set what search field is used for display
    # purposes on the result page.
    def self.set_search_display_key(value)
      @search_display_key = value.to_sym
    end

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
