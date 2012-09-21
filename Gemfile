source "http://rubygems.org"

gem 'sinatra'
gem 'erubis'
gem 'json'
gem 'unicorn'
gem "rack-flash3", "~> 1.0.1"
gem 'sinatra-contrib'
gem 'oauth2'
gem 'activerecord'
gem 'sinatra-session'
gem 'uuidtools'
gem 'rake'
gem 'activerecord-postgresql-adapter'
gem 'tire'
gem 'liquid'
gem 'postgres_ext'

group :test, :development do
  gem 'rspec'
  gem 'random-word'
  gem 'shotgun'
  gem 'pry'
end

group :plugins do
  # Install gems from each plugin
  paths = File.join(File.expand_path(File.dirname(__FILE__)), 'plugins')
  if ENV['PLUGIN_PATHS']
    paths += ':' + ENV['PLUGIN_PATHS']
  end
  paths.split(':').each do |path|
    Dir.glob(File.join(path, '**', 'Gemfile')) do |gemfile|
      eval(IO.read(gemfile), binding)
    end
  end
end
