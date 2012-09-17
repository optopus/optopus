module Optopus
  class App
    helpers do
      def display_search_result(result, display_key)
        display = nil
        if @timestamp_method && !@timestamp_method.blank?
          timestamp = result.send(@timestamp_method.to_sym)
          unless timestamp.nil?
            timestamp = Time.parse(timestamp)
            display = "#{timestamp.strftime("%D %R")} : #{result.to_hash[display_key]}"
          end
        end

        display = "#{result.to_hash[display_key]}" if display.nil?
        display
      end
    end

    get '/search' do
      begin
        validate_param_presence 'query'
        @search_query = params['query']
        @timestamp_method = params['with-timestamps']

        # Allow users to show a timestamp by specifying with-timestamps=:column
        if params.include?('with-timestamps') && !params['with-timestamps'].empty?
          @timestamp_method == params['with-timestamps'].to_sym
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
