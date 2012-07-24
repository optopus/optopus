require 'oauth2'
module Optopus
  module Auth
    module OAuth2
      include Optopus::Auth

      module Helpers
        def oauth_client
          if !@auth_client
            @oauth_client = ::OAuth2::Client.new(
              settings.authorization['oauth2']['client_id'],
              settings.authorization['oauth2']['client_secret'],
              :site      => settings.authorization['oauth2']['site'],
              :token_url => settings.authorization['oauth2']['token_url']
            )
          end
          @oauth_client
        end

      end

      def self.registered(app)
        raise 'Missing required authorization settings' unless app.settings.respond_to?(:authorization)
        verify_settings(app.settings.authorization)
        app.helpers Optopus::Auth::OAuth2::Helpers

        app.get '/login' do
          session_start!
          session[:uuid] = UUIDTools::UUID.random_create.to_s
          redirect_uri = URI.parse(request.url)
          redirect_uri.path = '/login/callback'
          redirect oauth_client.auth_code.authorize_url(:redirect_uri => redirect_uri.to_s, :state => session[:uuid])
        end

        app.get '/login/callback' do
          if session[:uuid] == params[:state]
            begin
              token = oauth_client.auth_code.get_token(params[:code])
              response = JSON.parse(token.get('/accounts/current').body)
              user = Optopus::User.where(:username => response['username']).first || Optopus::User.new(:username => response['username'], :display_name => response['username'])
              user.properties ||= Hash.new
              user.properties[:auth_data] = response.to_json
              user.properties[:email] = response['email']
              user.save!
              session[:oauth_token] = token.token
              session[:username] = user.username
              session[:user_id] = user.id
            rescue OAuth2::Error => error
              logger.error "OAuth2::Error: #{error.description}"
            rescue Exception => error
              logger.error "Unexpected error: #{error}"
            end
            redirect params.include?('redirect') ? params['redirect'] : '/'
          else
            status 400
          end
        end
      end

      private

      def self.verify_settings(settings)
        raise 'Missing oauth2 settings' unless settings.include?('oauth2')
        raise 'Missing oauth2 client_id' unless settings['oauth2'].include?('client_id')
        raise 'Missing oauth2 client_secret' unless settings['oauth2'].include?('client_secret')
        raise 'Missing oauth2 site' unless settings['oauth2'].include?('site')
        raise 'Missing oauth2 token_url' unless settings['oauth2'].include?('token_url')
      end

    end
  end
end
