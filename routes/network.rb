module Optopus
  class App

    def network_from_params
      @network = Optopus::Network.find_by_id(params[:id])
      if @network.nil?
        status 404
        flash[:error] = "Network with id #{params[:id]} does not exist!"
      end
    end

    def address_from_params
      @address = @network.addresses.find_by_ip_address(params[:ip])
      if @address.nil?
        status 404
        flash[:error] = "Network with id #{params[:id]} does not have IP address #{params[:ip]}"
      end
    end

    get '/networks' do
      @lonely_addresses = Optopus::Address.lonely.includes(:interface)
      unless @lonely_addresses.empty?
        @subnav = [ { :id => 'lonely-addresses', :name => 'Lonely Addresses' } ]
      end
      subnav_from_locations
      erb :networks
    end

    put '/network', :auth => [:admin, :network_admin] do
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
        register_event "{{ references.user.to_link }} created network #{network.address.to_cidr}", :type => 'network', :references => [ network ]
      rescue Exception => e
        handle_error(e)
      end

      status 201
      flash[:success] = "Successfully created new network for #{network.address.to_cidr}!"
      redirect back
    end

    get '/network/:id' do
      network_from_params
      @addresses = @network.addresses.paginate(:page => params[:page], :per_page => (params[:per_page] || 50))
      erb :network
    end

    get '/network/:id/available_ips', :provides => :json do
      network_from_params
      @network.available_ips.to_json
    end

    # Simple edit form that is loaded into a modal
    get '/network/:id/edit', :auth => :admin do
      network_from_params
      erb :edit_network
    end

    get '/network/:id/add_property', :auth => [:admin, :network_admin] do
      network_from_params
      @property_action = "/network/#{params[:id]}/add_property"
      @title = "Add property for #{@network.address.to_cidr}"
      erb :add_property
    end

    post '/network/:id/add_property', :auth => [:admin, :network_admin] do
      begin
        network_from_params
        validate_param_presence 'property-key', 'property-value'
        key = params['property-key']
        value = params['property-value']
        action = @network.properties.has_key?(key) ? 'updated' : 'added'
        @network.properties[key] = value
        @network.save!
        register_event "{{ references.user.to_link }} #{action} property '#{key} => #{value}' on #{@network.address.to_cidr}",
                       :type => 'network', :references => [ @network ]
      rescue Exception => e
        handle_error(e)
      end

      flash[:success] = "Successfully added new property '#{key} => #{value}'!"
      redirect back
    end

    get '/network/:id/remove_property', :auth => [:admin, :network_admin] do
      network_from_params
      @property_action = "/network/#{params[:id]}/remove_property"
      @title = "Remove property for #{@network.address.to_cidr}"
      @properties = @network.properties
      erb :remove_property
    end

    delete '/network/:id/remove_property', :auth => [:admin, :network_admin] do
      begin
        network_from_params
        validate_param_presence 'property-key'
        key = params['property-key']
        @network.properties.delete(key)
        @network.save!
        register_event "{{ references.user.to_link }} removed property '#{key}' from #{@network.address.to_cidr}",
                       :type => 'network', :references => [ @network ]
      rescue Exception => e
        handle_error(e)
      end

      flash[:success] = "Successfully removed property '#{key}' from network!"
      redirect back
    end

    post '/network/:id/edit', :auth => [:admin, :network_admin] do
      begin
        network_from_params
        raise 'Network does not exist!' if @network.nil?
        description = params['network-description']
        netmask = params['network-bits']
        location_id = params['network-location-id']
        network_address = params['network-address']
        vlan_id = params['network-vlan-id']

        location = Optopus::Location.find_by_id(location_id)
        raise 'Invalid location!' if location.nil?
        @network.location = location

        if !netmask.blank? && !network_address.blank?
          cidr = "#{network_address}/#{netmask}"
          if @network.address.to_cidr != cidr
            @network.address = cidr
          end
        end

        @network.vlan_id = vlan_id unless vlan_id.blank?
        @network.description = description unless description.blank?
        @network.save!
        register_event "{{ references.user.to_link }} updated network #{@network.address.to_cidr}", :type => 'network', :references => [ @network ]
      rescue Exception => e
        handle_error(e)
      end

      flash[:success] = "Successfully updated #{@network.address.to_cidr}!"
      redirect back
    end

    # Simple delete form that is loaded into a modal
    get '/network/:id/delete', :auth => [:admin, :network_admin] do
      network_from_params
      erb :delete_network
    end

    delete '/network/:id', :auth => [:admin, :network_admin] do
      begin
        network_from_params
        raise 'Network does not exist!' if @network.nil?
        @network.destroy
        register_event "{{ references.user.to_link }} deleted network #{@network.address.to_cidr}", :type => 'network', :references => [ @network ]
      rescue Exception => e
        handle_error(e)
      end
      flash[:success] = "Successfully deleted #{@network.address.to_cidr}!"
      redirect back
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
        register_event "{{ references.user.to_link }} allocated #{address.ip_address.to_s}", :type => 'network', :references => [ network, address ]
      rescue Exception => e
        handle_error(e)
      end

      status 201
      flash[:success] = "Successfully allocated #{address.ip_address.to_s}!"
      redirect back
    end

    get '/network/:id/address/:ip' do
      begin
        network_from_params
        @address = @network.addresses.find_by_ip_address(params[:ip])
        raise 'invalid IP for network!' if @address.nil?
        erb :address
      rescue Exception => e
        status 404
        flash[:error] = "#{params[:ip]} does not exist in network #{@network.id}"
        redirect "/network/#{@network.id}"
      end
    end

    post '/network/:id/address/:ip', :auth => [:admin, :network_admin] do
      begin
        network_from_params
        address_from_params
        raise 'Address does not exist!' if @address.nil?
        description = params['address-description']
        @address.description = description
        @address.save!
        register_event "{{ references.user.to_link }} updated address #{@address.ip_address}", :type => 'network', :references => [ @address ]
      rescue Exception => e
        handle_error(e)
      end

      flash[:success] = "Successfully updated #{@network.address.to_cidr}!"
      redirect back
    end

    delete '/network/:id/address/:ip', :auth => [:admin, :network_admin] do
      begin
        network_from_params
        address_from_params
        raise 'Address does not exist!' if @address.nil?
        @address.destroy
        register_event "{{ references.user.to_link }} deleted address #{@address.ip_address}", :type => 'network', :references => [ @address ]
      rescue Exception => e
        handle_error(e)
      end
      flash[:success] = "Successfully deleted #{@address.ip_address}!"
      redirect "/network/#{@network.id}"
    end

    get '/network/:id/address/:ip/delete', :auth => [:admin, :network_admin] do
      network_from_params
      address_from_params
      erb :delete_address
    end

    get '/network/:id/address/:ip/edit', :auth => [:admin, :network_admin] do
      network_from_params
      address_from_params
      erb :edit_address
    end

    get '/network/:id/address/:ip/add_property', :auth => [:admin, :network_admin] do
      network_from_params
      address_from_params
      @property_action = "/network/#{params[:id]}/address/#{params[:ip]}/add_property"
      @title = "Add property for #{@address.ip_address.to_s}"
      erb :add_property
    end

    post '/network/:id/address/:ip/add_property', :auth => [:admin, :network_admin] do
      begin
        network_from_params
        address_from_params
        validate_param_presence 'property-key', 'property-value'
        key = params['property-key']
        value = params['property-value']
        action = @address.properties.has_key?(key) ? 'updated' : 'added'
        @address.properties[key] = value
        @address.save!
        register_event "{{ references.user.to_link }} #{action} property '#{key} => #{value}' on #{@address.ip_address}",
                       :type => 'network', :references => [ @address ]
      rescue Exception => e
        handle_error(e)
      end

      flash[:success] = "Successfully added new property '#{key} => #{value}'!"
      redirect back
    end

    get '/network/:id/address/:ip/remove_property', :auth => [:admin, :network_admin] do
      network_from_params
      address_from_params
      @property_action = "/network/#{params[:id]}/address/#{params[:ip]}/remove_property"
      @title = "Remove property for #{@address.ip_address.to_s}"
      @properties = @address.properties
      erb :remove_property
    end

    delete '/network/:id/address/:ip/remove_property', :auth => [:admin, :network_admin] do
      begin
        network_from_params
        address_from_params
        validate_param_presence 'property-key'
        key = params['property-key']
        @address.properties.delete(key)
        @address.save!
        register_event "{{ references.user.to_link }} removed property '#{key}' from #{@address.ip_address.to_s}",
                       :type => 'network', :references => [ @address ]
      rescue Exception => e
        handle_error(e)
      end

      flash[:success] = "Successfully removed property '#{key}' from address!"
      redirect back
    end

  end
end
