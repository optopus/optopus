$: << File.expand_path(File.dirname(__FILE__) + '/lib')
source "http://rubygems.org"

gem 'sinatra'
gem 'erubis'
gem 'json'
gem 'unicorn'
gem "rack-flash3", "~> 1.0.1"
gem 'sinatra-contrib'
gem 'oauth2'
gem 'gravtastic'
gem 'activerecord'
gem 'sinatra-session'
gem 'sanitize'
gem 'uuidtools'
gem 'rake'
gem 'activerecord-postgresql-adapter'
gem 'tire'
gem 'liquid'
gem 'postgres_ext'
gem 'will_paginate', '~> 3.0.0'
gem 'will_paginate-bootstrap'

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
