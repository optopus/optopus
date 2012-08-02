module Optopus
  class App
    class ParamError < StandardError; end

    helpers do
      def html_id(string)
        string.downcase.gsub(' ', '_')
      end

      def logged_in?
        is_user?
      end

      def is_user?
        @user != nil
      end

      def locations
        @locations ||= Optopus::Location.all
      end

      def handle_error(exception, status_code=400)
        logger.error exception.to_s
        logger.info exception.backtrace.join("\t\n")
        flash[:error] = exception.to_s
        status status_code
        redirect back
      end

      def validate_param_presence(*keys)
        keys.each do |key|
          raise ParamError, "Missing required parameter: '#{key}'" unless params.include?(key) && !params[key].empty?
        end
      end

      def display_login_or_logout
        logged_in? ? "<a href=\"/logout\">Logout</a>" : "<a href=\"/login?redirect=#{URI.escape(request.fullpath)}\">Login</a>"
      end

      def subnav_from_locations
        @subnav = locations.inject(Array.new) do |subnav, location|
          subnav << { :id => html_id(location.common_name), :name => location.common_name.upcase }
        end
      end
    end
  end
end
