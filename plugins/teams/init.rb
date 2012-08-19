require_relative 'lib/teams_methods'
module Optopus
  module Plugin
    module Teams
      extend Optopus::Plugin

      plugin do
        register_mixin :roles, TeamsMethods::Role
        register_role 'teams_admin'
      end

      get '/teams/admin', :auth => 'teams_admin' do
        @teams = Optopus::Role.teams
        erb :teams_admin
      end

    end
  end
end
