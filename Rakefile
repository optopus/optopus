require 'app'
require 'active_record/fixtures'
require 'rspec/core/rake_task'

Dir.glob("#{File.expand_path(Optopus::App.root)}/rake/*.rake") { |r| import r }

# Import rake tasks from plugins
Optopus::Plugins.paths.each do |plugin_path|
  Dir.glob(File.join(plugin_path, '*', 'rake', '*.rake')) { |r| import r }
end

namespace :db do
  task :environment do
    require 'active_record'
  end

  desc 'Migrate the database'
  task(:migrate => :environment) do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate('db/migrate', ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
  end

  desc 'Load up seed data'
  task(:seed => :environment) do
    require_relative 'db/seed'
  end

  namespace :migrate do
    desc 'Migrate the database for plugins, set PLUGIN fo specific plugins or VERSION for specific version'
    task(:plugins => :environment) do
      ActiveRecord::Base.logger = Logger.new(STDOUT)
      ActiveRecord::Base.timestamped_migrations = true
      ActiveRecord::Migration.verbose = true
      Optopus::Plugins.list_registered.each do |plugin|
        if !ENV['PLUGIN'] || ENV['PLUGIN'] == plugin.to_s
          migrate_dir = File.join(plugin.plugin_settings[:plugin_path], 'db', 'migrate')
          if File.exists?(migrate_dir)
            ActiveRecord::Base.table_name_prefix = "plugin_#{plugin.to_s.demodulize.underscore}_"
            ActiveRecord::Migrator.migrate(migrate_dir, ENV['VERSION'] ? ENV['VERSION'].to_i : nil)
          end
        end
      end
    end
  end

  namespace :fixtures do
    desc 'Load fixtures'
    task(:load => :environment) do
      fixtures = ENV['FIXTURES'] ? ENV['FIXTURES'].split(/,/) : Dir.glob(File.join(File.dirname(__FILE__), 'test', 'fixtures', '*.{yml,csv}'))
      fixtures.each do |fixture_file|
        ActiveRecord::Fixtures.create_fixtures('test/fixtures', File.basename(fixture_file, '.*'))
      end
    end
  end
end

RSpec::Core::RakeTask.new do |spec|
  spec.pattern = './test/spec{,/*/**}/*_spec.rb'
end

task :test do
  require './test/spec/spec_helper'
  Optopus::Node.destroy_all
  Optopus::Device.destroy_all
  Optopus::Location.destroy_all
  Optopus::User.destroy_all
  Optopus::Role.destroy_all
  Optopus::Event.destroy_all
  Optopus::Network.destroy_all
  Optopus::Address.destroy_all
  Rake::Task['db:migrate'].invoke
  Rake::Task['spec'].invoke
end
