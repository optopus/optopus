module Optopus
  module Search
    def self.query(string, max_result_size=2000)
      query_string = make_valid_query_string(string)
      results = []

      # Loop through each of the models, checking if they respond to search
      # if they do, perform a search and store the results
      Optopus::Models.list.each do |model|
        next unless model.respond_to?(:search)
        search_options = model.respond_to?(:search_options) ? model.search_options : Hash.new
        highlight_fields = model.respond_to?(:highlight_fields) ? model.highlight_fields : nil
        result_set = model.search(:size => max_result_size) do
          query do
            string query_string, search_options
          end
          highlight *highlight_fields if highlight_fields
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
        if query_part.match(/(hostname|switch|macaddress|productname|facts\..*|event_type|event_message):(.*)/)
          query_string << "#{$1}:#{elasticsearch_escape($2)}"
        else
          query_string << elasticsearch_escape(query_part)
        end
      end
      query_string.join(' ')
    end
  end
end
