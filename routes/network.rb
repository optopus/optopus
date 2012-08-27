module Optopus
  class App
    get '/networks' do
      @networks = Optopus::Network.all
      erb :networks
    end

    get '/network/:id' do
      @network = Optopus::Network.find_by_id(params[:id])
      if @network.nil?
        status 404
        flash[:error] = "Network with id #{params[:id]} does not exist!"
      end
      # TODO: create view into this data
    end
  end
end
