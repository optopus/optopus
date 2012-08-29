module Optopus
  class App
    get '/networks' do
      @lonely_addresses = Optopus::Address.lonely
      unless @lonely_addresses.empty?
        @subnav = [ { :id => 'lonely-addresses', :name => 'Lonely Addresses' } ]
      end
      subnav_from_locations
      erb :networks
    end

    put '/network' do
      begin
        validate_param_presence 'network-address', 'network-bits', 'network-location-id'
        unless params['network-bits'].to_i.between?(1, 32)
          raise 'network bits must be an integer between 1 and 32'
        end

        unless params['network-address'].match(/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/)
          raise 'invalid network address specified, must contain four octets'
        end

        location = Optopus::Location.find_by_id(params['network-location-id'])
        raise 'invalid location' if location.nil?
        network = Optopus::Network.new(
          :address     => "#{params['network-address']}/#{params['network-bits']}",
          :vlan_id     => params['network-vlan-id'],
          :description => params['network-description']
        )
        network.location = location
        network.save!
      rescue Exception => e
        handle_error(e)
      end

      status 201
      flash[:success] = "Successfully created new network for #{network.address.to_cidr}!"
      redirect back
    end

    get '/network/:id' do
      @network = Optopus::Network.find_by_id(params[:id])
      if @network.nil?
        status 404
        flash[:error] = "Network with id #{params[:id]} does not exist!"
      end
      erb :network
    end

    put '/network/:id/allocate' do
      begin
        validate_param_presence 'ip-address'
        network = Optopus::Network.find_by_id(params[:id])
        raise 'invalid network!' if network.nil?
        address = network.addresses.create!(
          :ip_address => params['ip-address'],
          :description => params['ip-description']
        )
      rescue Exception => e
        handle_error(e)
      end

      status 201
      flash[:success] = "Successfully allocated #{address.ip_address.to_s}!"
      redirect back
    end
  end
end
