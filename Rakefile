require 'app'
require 'active_record/fixtures'

namespace :db do
  task :environment do
    require 'active_record'
    db_config = YAML::load(File.open(File.join(File.dirname(__FILE__), 'config', 'databases.yaml')))[Inventory::App.environment.to_s]
    ActiveRecord::Base.establish_connection(db_config)
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
