require 'app'
require 'active_record/fixtures'
require 'rspec/core/rake_task'

Dir.glob("#{File.expand_path(Optopus::App.root)}/rake/*.rake") { |r| import r }

namespace :db do
  task :environment do
    require 'active_record'
  end

  desc 'Migrate the database'
  task(:migrate => :environment) do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate('db/migrate')
  end

  desc 'Load up seed data'
  task(:seed => :environment) do
    require_relative 'db/seed'
  end

  namespace :migrate do
    desc 'Migrate the database for plugins'
    task(:plugins => :environment) do
      ActiveRecord::Base.logger = Logger.new(STDOUT)
      ActiveRecord::Base.timestamped_migrations = true
      ActiveRecord::Base.table_name_prefix = 'plugin_'
      ActiveRecord::Migration.verbose = true
      plugins_path = ENV['PLUGINS_PATH'] || File.join(File.expand_path(Optopus::App.root), 'plugins')
      Dir.glob(File.join(plugins_path, '*', 'db', 'migrate')).each do |migrate_dir|
        ActiveRecord::Migrator.migrate(migrate_dir)
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
  Rake::Task['db:migrate'].invoke
  Rake::Task['spec'].invoke
end
