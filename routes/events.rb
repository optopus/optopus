module Optopus
  class App
    get '/events' do
      @events = Optopus::Event.order('created_at DESC').all
      erb :events
    end
  end
end
