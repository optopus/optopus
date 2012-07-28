module Optopus
  class App
    get '/bare_metal' do
      subnav_from_locations
      erb :bare_metal
    end
  end
end
