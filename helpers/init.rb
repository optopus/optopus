module Optopus
  class App
    class ParamError < StandardError; end

    helpers do
      def html_id(string)
        string.downcase.gsub(' ', '_')
      end

      def locations
        @locations ||= Optopus::Location.all
      end

      def validate_param_precense(*keys)
        keys.each do |key|
          raise ParamError, "Missing required parameter: '#{key}'" unless params.include?(key)
        end
      end

      def subnav_from_locations
        @subnav = locations.inject(Array.new) do |subnav, location|
          subnav << { :id => html_id(location.common_name), :name => location.common_name.upcase }
        end
      end
    end
  end
end
