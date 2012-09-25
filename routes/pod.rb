module Optopus
  class App
    get '/pods/:id' do
      @pod = Optopus::Pod.find_by_id(params[:id])
      erb :pod
    end
  end
end
