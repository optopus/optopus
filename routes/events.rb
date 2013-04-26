module Optopus
  class App
    get '/events' do
      @events = Optopus::Event.order('created_at DESC').paginate(:page => params[:page], :per_page => (params[:per_page] || 50))
      erb :events
    end
  end
end
