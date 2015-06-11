$: << File.expand_path(File.dirname(__FILE__) + '/lib')
source "https://rubygems.org"
source "http://gems.shuttercorp.net"

gem 'rack', '1.4.1'
gem "activesupport", "3.2.8"
gem "nokogiri", "~> 1.5.6"
gem "pg_array_parser", "0.0.4" 
gem "sanitize", "2.0.3"
gem 'sinatra', "1.3.3"
gem 'erubis'
gem 'json'
gem 'yajl-ruby'
gem 'unicorn'
gem "rack-flash3", "~> 1.0.1"
gem 'sinatra-contrib', '1.3.1'
gem 'oauth2'
gem 'gravtastic'
gem 'activerecord', '3.2.8'
gem 'sinatra-session'
gem 'uuidtools'
gem 'rake'
gem 'activerecord-postgresql-adapter'
gem 'tire'
gem 'liquid', '2.4.1'
gem 'postgres_ext', '0.0.6'
gem 'will_paginate', '~> 3.0.0'
gem 'will_paginate-bootstrap', '0.2.2'

group :test, :development do
  gem 'rspec'
  gem 'random-word'
  gem 'shotgun'
  gem 'pry'
end

group :plugins do
  require 'optopus/plugins'
  # Install gems from each plugin
  Optopus::Plugins.paths.each do |path|
    Dir.glob(File.join(path, '*', 'Gemfile')) do |gemfile|
      eval(IO.read(gemfile), binding)
    end
  end
end
