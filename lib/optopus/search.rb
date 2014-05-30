module Optopus
  module Search
    def self.query(string, options={})
      raise 'Options must be a hash' unless options.kind_of?(Hash)
      # We assume that sort_options is { 'field' => '(asc,desc)' }
      sort_options = options.delete(:sort)
      query_string = make_valid_query_string(string)
      filter_options = options.delete(:filter)
      types = options.delete(:types)
      max_result_size = options.delete(:max_result_size) || 2000
      results = []

      # Ruby 1.9.3+ compatibility since String is no longer an Enumerable
      if types.kind_of?(String)
        types = types.lines
      end

      # Loop through each of the models, checking if they respond to search
      # if they do, perform a search and store the results
      models = types ? types.map { |t| Optopus::Models.type(t) } : Optopus::Models.list
      models.each do |model|
        next unless model.respond_to?(:search)
        search_options = model.respond_to?(:search_options) ? model.search_options : Hash.new
        highlight_fields = model.respond_to?(:highlight_fields) ? model.highlight_fields : nil
        result_set = model.search(:size => max_result_size) do
          query do
            string query_string, search_options
          end
          if sort_options
            sort do
              sort_options.each do |field, sort_type|
                by field, sort_type
              end
            end
          end
          highlight *highlight_fields if highlight_fields
          filter *filter_options if filter_options
        end
        if result_set.size > 0
          results << { :type => model.to_s.demodulize.underscore, :result_set => result_set, :display_key => model.search_display_key }
        end
      end
      results
    end

    private

    def self.elasticsearch_escape(string)
      if string.include?('*')
        # if the string has a wildcard, escape it properly for elasticsearch
        string.gsub(/[\{\}\[\]\(\):]/) { |s| "\\#{s}" }
      else
        "\"#{string}\""
      end
    end

    def self.make_valid_query_string(string)
      query_string = Array.new
      string.split.each do |query_part|
        if query_part.match(/([a-zA-Z-_]+):(.*)/)
          query_string << "#{$1}:#{elasticsearch_escape($2)}"
        else
          query_string << elasticsearch_escape(query_part)
        end
      end
      query_string.join(' ')
    end
  end
end
