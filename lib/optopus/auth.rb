module Optopus
  module Auth
    def self.registered(app)
      if app.settings.respond_to?(:authorization)
        type = app.settings.authorization['type']
        Optopus::Auth.constants.each do |const|
          if type == const.downcase
            puts "Loading auth plugin: #{const}"
            app.register Optopus::Auth.const_get(const)
          end
        end
      end

      app.get '/logout' do
        session.clear
        redirect back
      end
    end
  end
end
