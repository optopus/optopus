module Optopus
  def self.register_model(name)
    @models ||= []
    @models << name
    @models
  end

  def self.models
    Optopus.constants.each do |const_name|
      constant = Optopus.const_get(const_name)
      if !constant.nil? && constant.is_a?(Class)
        if constant.superclass == ActiveRecord::Base || constant.superclass == Optopus::Plugin::Model
          @models << constant
        end
      end
    end
    @models
  end
end

require 'optopus/plugin'
require 'optopus/plugins'
require 'optopus/auth'
require 'optopus/auth/oauth2'
require 'optopus/auth/database'
