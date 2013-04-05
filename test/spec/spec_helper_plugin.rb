require 'rspec/core'
require 'rack/test'
require 'sinatra/base'

module Optopus
  class App < Sinatra::Base
    configure do
      set :environment, :test
      set :raise_errors, :true
      set :logging, :false
    end
  end
end

require File.join(File.dirname(__FILE__), '..', '..', 'app')

def app
  Optopus::App
end

# Seems to run tests more than once if we do RSpec.configure more than once
unless RSpec.configuration.color_enabled == true
  RSpec.configure do |config|
    config.include Rack::Test::Methods
    config.color_enabled = true
    config.formatter = :documentation
  end
end

