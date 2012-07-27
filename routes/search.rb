module Optopus
  class App
    get '/search' do
      validate_param_presence 'query'
      @results = Array.new
      puts params['query']
      @results << Optopus::Node.search(params['query'])
      @results << Optopus::Appliance.search(params['query'])
      p @results
      erb :search_results
    end
  end
end
