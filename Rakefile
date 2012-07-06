require 'app'
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
end
