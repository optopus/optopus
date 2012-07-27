module Optopus
  class App
    get '/search' do
      validate_param_presence 'query'
      search_query = params['query']
      @results = Array.new
      puts "search_query: #{search_query}"
      nodes = Optopus::Node.search(:size => 2000) do
        query { string search_query }
        sort { by :hostname, 'desc' } 
      end
      @results << { :type => :node, :results => nodes }
      @results << { :type => :appliance, :results => Optopus::Appliance.search(params['query']) }
      erb :search_results
    end
  end
end
