module Optopus
  class App
    before do
      @user = Optopus::User.where(:id => session[:user_id]).first
    end

    get '/' do
      @appliances_to_be_provisioned = Optopus::Appliance.where(:provisioned => false)
      erb :index
    end
  end
end
