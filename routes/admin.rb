module Optopus
  class App
    admin_menu = Optopus::Menu::Section.new(:name => 'admin_menu', :required_role => 'admin')
    admin_menu.add_link :display => 'Users', :href => '/admin/users'
    Optopus::Menu.register_section(admin_menu)

    before '/admin/*', :auth => :admin do; end

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
