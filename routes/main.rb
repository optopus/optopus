module Optopus
  class App
    before do
      @user = Optopus::User.where(:id => session[:user_id]).first
    end

    get '/' do
      @devices_to_be_provisioned = Optopus::Device.where(:provisioned => false)
      erb :index
    end
  end
end
