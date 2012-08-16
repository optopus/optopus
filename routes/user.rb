module Optopus
  class App
    get '/user/:username' do
      @show_user = Optopus::User.where(:username => params[:username]).first
      erb :user
    end
  end
end
