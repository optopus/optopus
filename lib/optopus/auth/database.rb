require 'oauth2'
module Optopus
  module Auth
    module Database
      include Optopus::Auth

      module Helpers
        def password_hash(string)
          hash = Digest::SHA2.new << string
          hash.to_s
        end
      end

      def self.registered(app)
        raise 'Missing required authorization settings' unless app.settings.respond_to?(:authorization)
        app.helpers Optopus::Auth::Database::Helpers

        app.template :database_login do
          template = Array.new
          template << '<form class="form-horizontal" method="post">'
          template << '  <fieldset>'
          template << '     <div class="control-group">'
          template << '       <label class="control-label" for="username">Username</label>'
          template << '       <div class="controls">'
          template << '         <input class="input-large" type="text" name="username" id="username"/>'
          template << '       </div>'
          template << '     </div>'
          template << '     <div class="control-group">'
          template << '       <label class="control-label" for="password">Password</label>'
          template << '       <div class="controls">'
          template << '         <input class="input-large" type="password" name="password" id="password"/>'
          template << '       </div>'
          template << '     </div>'
          template << '     <div class="form-actions">'
          template << '       <input class="btn btn-primary" type="submit" value="Login"/>'
          template << '     </div>'
          template << '  </fieldset>'
          template << '</form>'
          template.join("\n")
        end

        app.get '/login' do
          session_start!
          session[:uuid] = UUIDTools::UUID.random_create.to_s
          erb :database_login
        end

        app.post '/login' do
          begin
            validate_param_presence 'password', 'username'
            user = User.where(:username => params['username']).first
            raise 'Invalid username or password' if user.nil? || user.password != password_hash(params['password'])
            session[:username] = user.username
            session[:user_id] = user.id
            redirect params.include?('redirect') ? params['redirect'] : '/'
          rescue Exception => e
            handle_error(e)
          end
        end
      end
    end
  end
end
