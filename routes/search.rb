module Optopus
  class App
    get '/search' do
      validate_param_presence 'query'
      # since we suck at using elasticsearch, split on the first : and assume someone searched for column_name:something
      query_string = ''
      params['query'].split.each do |and_query|
        query_parts = and_query.gsub(/[\{\}\[\]\(\)]/) { |s| "\\#{s}" }.split(':', 2)
        field = query_parts.first
        query = query_parts.last
        if query.nil?
          query_string += field + ' '
        elsif field == query
          # we only have a query, default to hostname for now
          query_string += "hostname:#{query}" + ' '
        else
          query = "\"#{query}\"" unless query.include?('*')
          query_string += "#{field}:#{query}" + ' '
        end
      end
      query_string.chomp!
      node_results = Optopus::Node.search(:size => 2000) do
        query { string query_string, :default_operator => 'AND' }
      end
      appliance_results = Optopus::Appliance.search(:size => 2000) do
        query { string query_string, :default_operator => 'AND' }
      end
      @search_query = params['query']
      @results = Array.new
      @results << { :type => :node, :results => node_results.sort { |a,b| a.hostname <=> b.hostname } }
      @results << { :type => :appliance, :results => appliance_results }
      erb :search_results
    end
  end
end
