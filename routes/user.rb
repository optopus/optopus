module Optopus
  class App
    get '/user/:username' do
      @show_user = Optopus::User.where(:username => params[:username]).first
      @admin_self = @user ? @show_user.id == @user.id : false
      erb :user
    end

    post '/user/:username/edit' do
      @edit_user = Optopus::User.where(:username => params[:username]).first
      unless @user && @edit_user.id == @user.id
        flash[:error] = 'You are not authorized to edit other users.'
        redirect back
      end

      if display_name = params.delete('display-name')
        @edit_user.display_name = display_name
      end

      begin
        @edit_user.save!
        flash[:success] = 'Successfully updated your display name!'
      rescue Exception => e
        handle_error(e)
      end

      redirect back
    end
  end
end
