module Optopus
  class App
    get '/search' do
      validate_param_presence 'query'
      #query = params['query'].gsub(/[\{\}\[\]\(\)]/) { |s| "\\#{s}" } + '*' # quick escaping
      # since we suck at using elasticsearch, split on the first : and assume someone searched for column_name:something
      query_parts = params['query'].gsub(/[\{\}\[\]\(\)]/) { |s| "\\#{s}" }.split(':', 2)
      field = query_parts.first
      query = query_parts.last
      query = "\"#{query}\"" unless query.include?('*')

      @search_query = params['query']
      @results = Array.new
      node_results = Optopus::Node.search(:size => 2000) do 
        query do
          string "#{field}:#{query}"
        end

        #(query, :size => 200)
      end
      @results << { :type => :node, :results => node_results.sort { |a,b| a.hostname <=> b.hostname } }
      @results << { :type => :appliance, :results => Optopus::Appliance.search("#{field}:#{query}") }
      erb :search_results
    end
  end
end
