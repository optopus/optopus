module Optopus
  class App
    get '/bare_metal' do
      subnav_from_locations
      erb :bare_metal
    end

    get '/devices/new' do
      subnav_from_locations
      @devices = Optopus::Device.where(:provisioned => false)
      erb :new_devices
    end

    get '/device/:id/delete', :auth => :admin do
      @device = Optopus::Device.where(:id => params[:id]).first
      erb :delete_device
    end

    delete '/device/:id', :auth => :admin do
      begin
        device = Optopus::Device.where(:id => params[:id]).first
        device.destroy
        flash[:success] = "Deleted device #{device.serial_number.upcase}/#{device.primary_mac_address.upcase} successfully!"
        register_event "{{ references.user.to_link }} deleted device #{device.serial_number.upcase}/#{device.primary_mac_address.upcase}", :type => 'device_deleted'
        redirect '/devices/new'
      rescue Exception => e
        handle_error(e)
      end
    end
  end
end
