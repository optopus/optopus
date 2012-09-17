module Optopus
  class App
    get '/search' do
      begin
        validate_param_presence 'query'
        @search_query = params['query']
        if params.include?('with-timestamps') && params['with-timestamps'] == 'true'
          @timestamps = true
        end

        # Allow users to sort by passing URL parameters matching sort_(field_name)
        sort = params.inject(Hash.new) do |sort, (param, value)|
          if param =~ /^sort_(\w+)$/ && ['asc', 'desc'].include?(value)
            sort[$1.to_sym] = value
          end
          sort
        end

        @results = Optopus::Search.query(params['query'], :sort => sort)
        erb :search_results
      rescue Exception => e
        handle_error(e)
      end
    end
  end
end
