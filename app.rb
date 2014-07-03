$: << File.expand_path(File.dirname(__FILE__) + '/lib')
require 'rubygems'
require 'yajl'
require 'yajl/json_gem'
require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra/reloader'
require 'sinatra/session'
require 'logger'
require 'rack-flash'
require 'core_ext/kernel'
require 'core_ext/string'
require 'core_ext/nil_class'
require 'core_ext/fixnum'
require 'core_ext/ipaddr'
require 'core_ext/time'
require 'erubis'
require 'attributes_to_liquid_methods_mapper'
require 'uuidtools'
require 'active_record'
require 'activerecord-postgres-hstore'
require 'activerecord-postgres-hstore/activerecord'
require 'optopus'
require 'tire'
require 'tire_monkey_patches'
require 'liquid'
require 'postgres_ext'
require 'postgres_ext_monkey_patches.rb'
require 'will_paginate'
require 'will_paginate/active_record'
require 'will_paginate-bootstrap'
require 'will_paginate-bootstrap_monkey_patches'

module Optopus
  class App < Sinatra::Base
    register Sinatra::ConfigFile
    register Sinatra::Session
    register WillPaginate::Sinatra
    application_config_file = ENV['OPTOPUS_CONFIG_FILE'] || File.expand_path(File.dirname(__FILE__) + '/config/application.yaml')
    config_file application_config_file
    set :root, File.dirname(__FILE__)
    enable :logging
    enable :sessions
    enable :method_override
    use Rack::Flash

    # Add QA to environments
    set :environments, %w{development test production qa}

    # TODO: move config file validation to a proper location
    if not settings.respond_to?(:plugins)
      raise "Invalid application config file detected! Please add the plugins key to #{application_config_file}"
    end

    register Optopus::Auth
    set(:auth) do |*roles|
      condition do
        unless roles.any? { |role| (role == :user) ? is_user? : is_authorized?(role) }
          handle_unauthorized_access
        end
      end
    end

    db_config_file = ENV['OPTOPUS_DATABASE_CONFIG_FILE'] || File.join(File.dirname(__FILE__), 'config', 'databases.yaml')
    db_config = YAML::load(File.open(db_config_file))[Optopus::App.environment.to_s]
    ActiveRecord::Base.establish_connection(db_config)
    Tire::Configuration.url settings.elasticsearch[:url]

    # This should be moved out into it's own file, but this is a quick way to add
    # query tracing to find a line of code that shows the calling information.
    module QueryTrace
      def self.enable!
        ::ActiveRecord::LogSubscriber.send(:include, self)
      end

      def self.append_features(klass)
        super
        klass.class_eval do
          unless method_defined?(:log_info_without_trace)
            alias_method :log_info_without_trace, :sql
            alias_method :sql, :log_info_with_trace
          end
        end
      end

      def backtrace_cleaner
        return @backtrace_cleaner if @backtrace_cleaner
        @backtrace_cleaner = ActiveSupport::BacktraceCleaner.new
        @backtrace_cleaner.add_filter { |line| line.gsub(Optopus::App.root, '.') }
        @backtrace_cleaner.add_silencer { |line| line =~ /activerecord|active_support/ }
      end

      def log_info_with_trace(event)
        log_info_without_trace(event)
        trace_log = backtrace_cleaner.clean(caller).first
        if trace_log && event.payload[:name] != 'SCHEMA'
          logger.debug("   \\_ \e[33mCalled from:\e[0m " + trace_log)
        end
      end
    end

    if ENV['DATABASE_DEBUG'] == 'true'
      ActiveRecord::Base.logger = Logger.new(STDOUT)
      QueryTrace.enable!
    end

    require_relative 'models/init'
    require_relative 'helpers/init'
    require_relative 'routes/init'

    register Optopus::Plugins

    # List of roles to include by default
    Optopus::Models.ensure_exists('Optopus::Role', :name => 'network_admin')

    # ensure any data registered by plugins exists
    # and that any mixins are included
    Optopus::Models.list.each do |model|
      # Only try to insert data if we have a schema, this is sort of a hack
      # since our Rakefile requires this file. If this is a brand new installation
      # and we're trying to run a db migration, it will fail because we try to insert
      # data into a non-existent schema.
      if ActiveRecord::Migrator.current_version > 0
        if register_data = Optopus::Models.model_data[model.to_s]
          puts "Running model data validationn for #{model}"
          register_data.each do |values|
            obj = model.where(values).first || model.new(values)
            obj.save!
          end
        end
      end
      if register_mixins = Optopus::Models.mixins[model.to_s]
        register_mixins.each do |mixin|
          model.send(:include, mixin)
        end
      end
    end

    # Override the default find_template method so that we search through each plugins views_path
    set :views, settings.optopus_plugins.inject([]) { |v, p| v << p[:views_path] if p.include?(:views_path) } << 'views'
    helpers do
      def find_template(views, name, engine, &block)
        Array(views).each { |v| super(v, name, engine, &block) }
      end

      def node_partials
        settings.partials[:node] || []
      end

      def user_profile_partials
        settings.partials[:user_profile] || []
      end
    end
  end
end

