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
  if File.exists?('db/test.sqlite3')
    File.unlink('db/test.sqlite3')
  end
  require './test/spec/spec_helper'
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  ActiveRecord::Migration.verbose = true
  ActiveRecord::Migrator.migrate('db/migrate')
  spec.pattern = './test/spec{,/*/**}/*_spec.rb'
end
