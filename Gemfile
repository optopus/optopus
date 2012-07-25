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

group :test, :development do
  gem 'rspec'
  gem 'sqlite3'
end

group :plugins do
  # Install gems from each plugin
  Dir.glob(File.join(File.dirname(__FILE__), 'plugins', '**', 'Gemfile')) do |gemfile|
    eval(IO.read(gemfile), binding)
  end
end
