module Optopus
  class App
    get '/search' do
      validate_param_presence 'query'
      # since we suck at using elasticsearch, split on the first : and assume someone searched for column_name:something
      query_parts = params['query'].gsub(/[\{\}\[\]\(\)]/) { |s| "\\#{s}" }.split(':', 2)
      field = query_parts.first
      query = query_parts.last
      if query.nil?
        query_string = field
      else
        query = "\"#{query}\"" unless query.include?('*')
        query_string = "#{field}:#{query}"
      end
      node_results = Optopus::Node.search(query_string, :size => 2000).sort { |a,b| a.hostname <=> b.hostname }
      appliance_results = Optopus::Appliance.search(query_string, :size => 2000)
      @search_query = params['query']
      @results = Array.new
      @results << { :type => :node, :results => node_results }
      @results << { :type => :appliance, :results => appliance_results }
      erb :search_results
    end
  end
end
