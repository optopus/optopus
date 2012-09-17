module Optopus
  class App
    get '/search' do
      begin
        validate_param_presence 'query'
        @search_query = params['query']
        if params.include?('with-timestamps') && params['with-timestamps'] == 'true'
          @timestamps = true
        end
        @results = Optopus::Search.query(params['query'])
        erb :search_results
      rescue Exception => e
        handle_error(e)
      end
    end
  end
end
