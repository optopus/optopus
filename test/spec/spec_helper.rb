require File.join(File.dirname(__FILE__), '..', '..', 'app')
require 'rack/test'
module Inventory
  class App
    set :environment, :test
    set :raise_errors, :true
    set :logging, :false
  end
end

def app
  Inventory::App
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.color_enabled = true
  config.formatter = :documentation
end
