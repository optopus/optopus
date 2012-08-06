module Optopus
  class App
    before do
      @user = Optopus::User.where(:id => session[:user_id]).first
    end

    get '/' do
      @devices_to_be_provisioned = Optopus::Device.where(:provisioned => false)
      @inactive_nodes = Optopus::Node.inactive.limit(5)
      @new_nodes = Optopus::Node.where('created_at > ?', 7.days.ago).order('created_at DESC').limit(5)
      @recent_events = Optopus::Event.order('created_at DESC').limit(5)
      @active_node_count = Optopus::Node.active.count
      erb :index
    end
  end
end
