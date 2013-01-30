module Optopus
  class App
    admin_menu = Optopus::Menu::Section.new(:name => 'admin_menu', :required_role => 'admin')
    admin_menu.add_link :display => 'Users', :href => '/admin/users'
    admin_menu.add_link :display => 'Pods', :href => '/admin/pods'
    Optopus::Menu.instance.register_section(admin_menu)

    def pod_from_params
      @pod = Optopus::Pod.find_by_id(params[:id])
      if @pod.nil?
        status 404
        flash[:error] = "Pod with id #{params[:id]} does not exist!"
      end
    end

    before '/admin/*', :auth => :admin do; end

    get '/admin/pods' do
      subnav_from_locations
      erb :pods
    end

    post '/admin/pod/:id/edit' do
      begin
        pod = Optopus::Pod.find_by_id(params[:id])
        raise 'Pod does not exist!' if pod.nil?

        if params['pod-name']
          register_event "{{ references.user.to_link }} renamed pod #{pod.name} to #{params['pod-name']} in #{pod.location.common_name}", :type => 'pod', :references => [ pod ]
          pod.name = params['pod-name']
          pod.save!
        end
      rescue Exception => e
        handle_error(e)
      end

      flash[:success] = "Successfully updated #{pod.name} in #{pod.location.common_name}!"
      redirect back
    end

    put '/admin/pod' do
      begin
        validate_param_presence 'pod-name', 'pod-location-id'
        location = Optopus::Location.find_by_id(params['pod-location-id'])
        raise 'invalid location' if location.nil?
        pod = location.pods.create!(:name => params['pod-name'])
        register_event "{{ references.user.to_link }} created pod #{pod.name} in #{pod.location.common_name}", :type => 'pod', :references => [ pod ]
      rescue Exception => e
        handle_error(e)
      end

      status 201
      flash[:success] = "Successfully created new pod in #{pod.location.common_name} called #{pod.name}!"
      redirect back
    end

    delete '/admin/pod/:id' do
      begin
        pod_from_params
        raise 'Pod does not exist!' if @pod.nil?
        @pod.destroy
        register_event "{{ references.user.to_link }} deleted pod #{@pod.name} in #{pod.location.common_name}", :type => 'pod'
      rescue Exception => e
        handle_error(e)
      end
      flash[:success] = "Successfully deleted #{@pod.name} from #{@pod.location.common_name}!"
      redirect back
    end

    # create form for pods
    get '/admin/pod/create' do
      erb :pod_create
    end

    # edit form for pods
    get '/admin/pods/:id/edit' do
      pod_from_params
      erb :pod_edit
    end

    # delete form for pods
    get '/admin/pods/:id/delete' do
      pod_from_params
      erb :pod_delete
    end

    get '/admin/users' do
      @modify_users = Optopus::User.all
      erb :users
    end

    get '/admin/user/:id/roles' do
      @roles = Optopus::Role.all
      @modify_user = Optopus::User.where(:id => params[:id]).first
      if @modify_user.nil?
        flash[:error] = 'User does not exist.'
        redirect back
      end
      erb :modify_user_roles, :layout => false
    end

    post '/admin/user/:id/roles' do
      @modify_user = Optopus::User.where(:id => params[:id]).first
      if @modify_user.nil?
        flash[:error] = 'User does not exist.'
        redirect back
      end

      new_roles = Array.new
      params.each do |key, value|
        if key =~ /^role_(.*)/
          role = Optopus::Role.where(:id => value).first
          next if role.nil?
          new_roles << role
        end
      end
      @modify_user.roles = new_roles
      redirect back
    end

    delete '/admin/user/:id' do
      user = Optopus::User.where(:id => params[:id]).first
      begin
        raise 'User does not exist.' if user.nil?
        user.destroy
        flash[:success] = "Deleted #{user.username} successfully!"
        redirect back
      rescue Exception => e
        handle_error(e)
      end
    end
  end
end
