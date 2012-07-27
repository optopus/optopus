module Optopus
  class App
    get '/search' do
      validate_param_presence 'query'
      @search_query = params['query']
      @results = Array.new
      @results << { :type => :node, :results => Optopus::Node.search(params['query']) }
      @results << { :type => :appliance, :results => Optopus::Appliance.search(params['query']) }
      erb :search_results
    end
  end
end
