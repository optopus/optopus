$: << File.expand_path(File.dirname(__FILE__) + '/lib')
require 'rubygems'
require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra/reloader'
require 'sinatra/session'
require 'logger'
require 'rack-flash'
require 'core_ext/kernel'

module Inventory
  class App < Sinatra::Base
    register Sinatra::ConfigFile
    register Sinatra::Session
    config_file File.expand_path(File.dirname(__FILE__) + '/config/application.yaml')
    set :root, File.dirname(__FILE__)
    enable :logging
    enable :sessions
    enable :method_override
    use Rack::Flash
  end
end

require_relative 'models/init'
require_relative 'helpers/init'
require_relative 'routes/init'
