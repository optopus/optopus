module Optopus
  class App
    get '/user/:id' do
      @show_user = Optopus::User.find_by_id(params[:id])
      erb :user
    end
  end
end
