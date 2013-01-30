module Optopus
  class App
    get '/events' do
      @events = Optopus::Event.order('created_at DESC').page(params[:page])
      erb :events
    end
  end
end
