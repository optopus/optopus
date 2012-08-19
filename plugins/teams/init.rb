require_relative 'lib/teams_methods'
module Optopus
  module Plugin
    module Teams
      extend Optopus::Plugin

      teams_admin_menu = Optopus::Menu::Section.new(:name => 'teams_admin_menu')
      teams_admin_menu.add_link :display => 'Teams', :href => '/teams/admin'
      teams_admin_menu.required_role = 'teams_admin'

      plugin do
        register_mixin :roles, TeamsMethods::Role
        register_role 'teams_admin'
        register_menu teams_admin_menu
      end

      get '/teams/admin', :auth => 'teams_admin' do
        @teams = Optopus::Role.teams
        erb :teams_admin
      end

    end
  end
end
