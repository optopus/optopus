module Optopus
  class App
    get '/' do
      @appliances_to_be_provisioned = Optopus::Appliance.where(:provisioned => false)
      erb :index
    end
  end
end
