module Optopus
  class App
    get '/search' do
      subnav_from_locations
      erb :search
    end
  end
end
