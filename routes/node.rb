module Optopus
  class App
    get '/nodes' do
      subnav_from_locations
      erb :nodes
    end
  end
end
