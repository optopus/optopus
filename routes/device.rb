module Optopus
  class App
    get '/bare_metal' do
      subnav_from_locations
      erb :bare_metal
    end

    get '/devices/new' do
      subnav_from_locations
      @devices = Optopus::Device.where(:provisioned => false)
      erb :new_devices
    end
  end
end
