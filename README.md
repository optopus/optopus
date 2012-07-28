# Optopus
Everyone's tired of having tons of different systems, optopus is designed to talk to your various systems using their API.

## Development
Requirements:
- Postgres 9.1 or higher with hstore extension
- elasticsearch
- Ruby 1.8.7, might also work on 1.9.x

To get started, install the necessary gems:

    # bundle install

Create a databases.yaml:

    # cp config/databases.yaml.example config/databases.yaml

Modify your databases.yaml to reflect your specific settings. Must use Postgresql because we rely on Hstore. You will also need to create your databases manually for now:

    CREATE DATABASE optopus_dev;
    CREATE DATABASE optopus_test;

Create an application.yaml:

    # cp config/application.yaml.example config/application.yaml

You will probably want to update the application config with any plugins you want enabled as well as putting the proper elasticsearch location in there.

Finally, run migrations to get necessary schema:

    # bundle exec rake db:migrate

If you want to populate some seed data for development:

    # bundle exec rake db:seed

The seed script located in <code>db/seed.rb</code> will generate 1000 random nodes by default. You can specify the <code>NODES</code> environment variable to generate different amounts.

Running rspec tests:

    # bundle exec rake test
