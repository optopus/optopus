module Optopus
  class App
    before do
      @user = Optopus::User.includes(:roles).where(:id => session[:user_id]).first
    end

    get '/' do
      @devices_to_be_provisioned = Optopus::Device.where(:provisioned => false)
      @inactive_nodes = Optopus::Node.inactive.limit(10)
      @new_nodes = Optopus::Node.where('created_at > ?', 10.days.ago).order('created_at DESC').limit(10)
      @recent_events = Optopus::Event.order('created_at DESC').limit(10)
      @active_node_count = Optopus::Node.active.count
      erb :index
    end

    get '/reports' do
      erb :reports
    end
  end
end
