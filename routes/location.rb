module Optopus
  class App
    get '/location/:common_name' do
      @location = Optopus::Location.find_by_common_name(params[:common_name])
      erb :location
    end
  end
end
