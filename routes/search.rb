module Optopus
  class App
    get '/search' do
      validate_param_presence 'query'
      @search_query = params['query']
      @results = Optopus::Search.query(params['query'])
      erb :search_results
    end
  end
end
