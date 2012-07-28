require 'app'
require 'active_record/fixtures'
require 'rspec/core/rake_task'

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
  Rake::Task['db:migrate'].invoke
  Rake::Task['spec'].invoke
end
