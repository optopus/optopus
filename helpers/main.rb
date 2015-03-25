module Optopus::AppHelpers::Main
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
    return @is_admin if @is_admin != nil
    if is_user?
      @is_admin = @user.roles.where(:id => admin_role.id).first != nil
    else
      @is_admin = false
    end
    return @is_admin
  end

  def is_server_admin?
    return @is_server_admin if @is_server_admin != nil
    if is_user?
      @is_server_admin = @user.roles.where(:id => server_admin_role.id).first != nil
    else
      @is_server_admin = false
    end
    return @is_server_admin
  end

  def admin_role
    @admin_role ||= Optopus::Role.where(:name => 'admin').first
  end

  def server_admin_role
    @server_admin_role ||= Optopus::Role.where(:name => 'server_admin').first
  end

  def locations
    @locations ||= Optopus::Location.order('common_name')
  end

  def handle_error(exception, status_code=400)
    logger.error exception.to_s
    logger.info exception.backtrace.join("\t\n")
    flash[:error] = exception.to_s
    status status_code
    redirect back
  end

  def handle_unauthorized_access(roles)
    if logged_in?
      flash[:error] = 'You are unauthorized.'
      logger.debug "Unauthorized access to #{request.url}, user must be #{roles.join(',')}"
      redirect '/' if request.referer.nil?
      redirect back
    else
      redirect_url = request.referer.nil? ? '/' : request.referer
      redirect "/login?redirect=#{URI.encode(redirect_url)}"
    end
  end

  def validate_param_presence(*keys)
    keys.each do |key|
      raise Optopus::App::ParamError, "Missing required parameter: '#{key}'" unless params.include?(key) && !params[key].empty?
    end
  end

  def display_login_or_logout
    case logged_in?
    when true
      erb :user_menu
    else
      "<li><a href=\"/login?redirect=#{URI.escape(request.fullpath)}\">Login</a></li>"
    end
  end

  def subnav_from_locations
    @subnav ||= Array.new
    @subnav += locations.inject(Array.new) do |subnav, location|
      subnav << { :id => html_id(location.common_name), :name => location.common_name.upcase }
    end
  end

  # return a progress style based on a given interger
  def progress_style(integer)
    case integer
    when 0..20
      'progress-success'
    when 21..60
      'progress-info'
    when 61..90
      'progress-warning'
    else
      'progress-danger'
    end
  end

  # Used to append badges to node links, example being to show nodes as dead
  def display_node_with_badges(node)
    link = node.to_link
    link += ' <span class="badge badge-important">dead</span>' unless node.active
    link
  end

  # returns an unstyled list from an array. attemps to turn the item into a link or a string
  def display_unstyled_list_from_array(array)
    list = '<ul class="unstyled">'
    array.each do |item|
      list += '<li>' + (item.respond_to?(:to_link) ? item.to_link : item.to_s)  + '</li>'
    end
    list += '</ul>'
  end

  def rickshaw_data_node_creation_by_day(days=nil)
    if days
      data = Optopus::Node.order('date_created_at ASC').where('created_at > ?', days.days.ago).count(:group => "DATE(created_at)")
    else
      data = Optopus::Node.order('date_created_at ASC').count(:group => "DATE(created_at)")
    end
    data.inject('[') do |data, (date, count)|
      data + "{ x: #{Time.parse(date).to_i}, y: #{count.to_i} },"
    end + ']'
  end

  def rickshaw_data_active_nodes_over_time
    Optopus::Event.order('created_at ASC').where("properties -> 'event_type' = 'node_count'").inject('[') do |data, event|
      data + "{ x: #{event.created_at.to_i}, y: #{event.properties['node_count'].to_i} },"
    end + ']'
  end

  def rickshaw_series_event_types_by_day(days=nil)
    Optopus::Event.unique_event_types.inject([]) do |series, event_type|
      data = Optopus::Event.group_event_type_by_created_at(event_type, days).inject([]) do |data, (date, count)|
        data << { :x => Time.parse(date).to_i, :y => count.to_i }
      end
      series << { :data => data, :name => event_type }
    end.to_json
  end

  def hypervisor_domains_like(hypervisor, matcher)
    hypervisor[:libvirt][:domains].map { |d| d.name }.grep( matcher )
  end

  def hypervisor_domains_like_badge(hypervisor, matcher)
    count = hypervisor_domains_like(hypervisor, matcher).count
    badge_class = case count
                  when 0
                    "badge-success"
                  when 1
                    "badge-warning"
                  else
                    "badge-important"
                  end

    "<span class='badge #{ badge_class }'>#{ count }</span>"
  end

  def hypervisor_domains_on_switch_like(hypervisor, node_name)
    nodes_on_switch_count = Optopus::Search.query("switch:#{ hypervisor[:switch] } hostname:*#{ node_name }*", :types => 'node').first.try(:[], :result_set)
    nodes_on_switch_count = nodes_on_switch_count.try(:count) || 0
  end

  def hypervisor_domains_on_switch_like_badge( hypervisor, node_name )
    count = hypervisor_domains_on_switch_like( hypervisor, node_name )
    badge_class = "badge-success"

    if count > 10 && count < 15
      badge_class = "badge-warning"
    elsif count >= 15
      badge_class = "badge-important"
    end

    "<span class='badge #{ badge_class }'>#{ count }</span>"
  end

  def base_url
    base = "#{request.scheme}://#{request.host}"
    if request.port != 80 || request.port != 443
      base += ":#{request.port}"
    end
    base
  end
end
