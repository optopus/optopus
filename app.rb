$: << File.expand_path(File.dirname(__FILE__) + '/lib')
require 'rubygems'
require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra/reloader'
require 'sinatra/session'
require 'logger'
require 'rack-flash'
require 'core_ext/kernel'
require 'core_ext/string'
require 'liquid'
require 'attributes_to_liquid_methods_mapper'
require 'uuidtools'
require 'active_record'
require 'activerecord-postgres-hstore'
require 'activerecord-postgres-hstore/activerecord'

module Optopus
  class App < Sinatra::Base
    register Sinatra::ConfigFile
    register Sinatra::Session
    config_file File.expand_path(File.dirname(__FILE__) + '/config/application.yaml')
    set :root, File.dirname(__FILE__)
    enable :logging
    enable :sessions
    enable :method_override
    use Rack::Flash

    db_config = YAML::load(File.open(File.join(File.dirname(__FILE__), 'config', 'databases.yaml')))[Optopus::App.environment.to_s]
    ActiveRecord::Base.establish_connection(db_config)
  end
end

require_relative 'models/init'
require_relative 'helpers/init'
require_relative 'routes/init'
