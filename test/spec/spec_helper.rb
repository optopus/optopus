require 'rack/test'
require 'sinatra/base'

module Inventory
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
  Inventory::App
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.color_enabled = true
  config.formatter = :documentation
end
