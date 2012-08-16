module Optopus
  class App
    class ParamError < StandardError; end

    helpers do
      def register_event(message, options={})
        references = options.delete(:references) || Array.new
        type = options.delete(:type) || 'generic'
        raise 'references must be an array' unless references.kind_of?(Array)
        event = Optopus::Event.new
        event.message = message
        references << @user
        references.each do |reference|
          event.properties["#{reference.class.table_name.singularize}_id"] = reference.id
        end
        event.type = type
        event.save!
      end

      def html_id(string)
        string.downcase.gsub(' ', '_')
      end

      def logged_in?
        is_user?
      end

      def is_user?
        @user != nil
      end

      def is_authorized?(role_name)
        return false unless is_user?
        role = Optopus::Role.where(:name => role_name).first
        raise "Invalid role name: #{role_name}" if role.nil?
        @user.member_of?(role.id)
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

      def handle_unauthorized_access
        if logged_in?
          flash[:error] = 'You are unauthorized.'
          logger.debug "Unauthorized access to #{request.url}, user must be #{type}"
          redirect '/' if request.referer.nil?
          redirect back
        else
          redirect_url = request.referer.nil? ? '/' : request.referer
          redirect "/login?redirect=#{URI.encode(redirect_url)}"
        end
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

      def rickshaw_data_node_creation_by_day
        Optopus::Node.order('date_created_at ASC').count(:group => "DATE(created_at)").inject('[') do |data, (date, count)|
          data + "{ x: #{Time.parse(date).to_i}, y: #{count.to_i} },"
        end + ']'
      end

      def rickshaw_data_active_nodes_over_time
        Optopus::Event.order('created_at ASC').where("properties -> 'event_type' = 'node_count'").inject('[') do |data, event|
          data + "{ x: #{event.created_at.to_i}, y: #{event.properties['node_count'].to_i} },"
        end + ']'
      end
    end
  end
end
