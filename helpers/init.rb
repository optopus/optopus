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

      def is_admin?
        return false unless is_user?
        @user.roles.where(:id => admin_role.id).first != nil
      end

      def admin_role
        @admin_role ||= Optopus::Role.where(:name => 'admin').first
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
        case logged_in?
        when true
          is_admin? ? erb(:admin_menu) : "<li><a href=\"/logout\">Logout</a></li>"
        else
          "<li><a href=\"/login?redirect=#{URI.escape(request.fullpath)}\">Login</a></li>"
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
