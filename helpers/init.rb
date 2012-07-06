module Inventory
  class App
    class ParamError < StandardError; end

    helpers do
      def validate_param_precense(*keys)
        keys.each do |key|
          raise ParamError, "Missing required parameter: '#{key}'" unless params.include?(key)
        end
      end
    end
  end
end
