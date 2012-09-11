module Optopus
  class App
    after '/api/*', :provides => :json do; end

    post '/api/node/register' do
      begin
        data = JSON.parse(request.body.read)
        hostname = data.delete('hostname')
        serial_number = data.delete('serial_number')
        primary_mac_address = data.delete('primary_mac_address')
        type = data.delete('type')
        facts = data.delete('facts')
        libvirt = data.delete('libvirt')
        virtual = data.delete('virtual')
        virtual = true if virtual == 'true'
        virtual = false if virtual == 'false'
        raise "No primary_mac_address supplied." if primary_mac_address.nil? || primary_mac_address.empty?
        raise "No hostname supplied." if hostname.nil? || hostname.empty?
        raise "No virtual supplied." unless virtual.kind_of?(TrueClass) || virtual.kind_of?(FalseClass)
        if not virtual
          raise "No serial_number supplied." if serial_number.nil? || serial_number.empty?
        end
        node = Optopus::Node.where(:hostname => hostname).first
        if node.nil?
          node = Optopus::Node.new(:hostname => hostname)
        end
        node.virtual = virtual
        node.hostname = hostname
        node.facts = facts
        node.active = true
        node.serial_number = serial_number unless serial_number.nil?
        node.primary_mac_address = primary_mac_address
        if libvirt
          unless node.kind_of?(Optopus::Hypervisor)
            # if the node registers with libvirt data
            # we will assume it should be of the Optopus::Hypervisor type
            node.type = 'Optopus::Hypervisor'
            node.save!
            # in order to access the libvirt_data method,
            # we have to re-initialize the node instance
            node = Optopus::Node.find_by_id(node.id)
          end
          node.libvirt_data = libvirt
        elsif type
          case type
          when 'network_node'
            unless node.kind_of?(Optopus::NetworkNode)
              node.type = 'Optopus::NetworkNode'
              node.save!
              node = Optopus::Node.find_by_id(node.id)
            end
          else
            # Silently ignore invalid types for now
          end
        end
        node.save!
        logger.info "Successful node registration via API: #{node.hostname}"
        status 202
      rescue JSON::ParserError => e
        status 400
        logger.error "Invalid JSON data: #{request.body.read}"
        body({ :user_error => 'invalid JSON'}.to_json)
      rescue Exception => e
        status 400
        logger.error "Received invalid data: #{e}"
        body({ :user_error => e.to_s }.to_json)
      end
    end

    post '/api/device/register' do
      begin
        validate_param_presence 'serial_number', 'primary_mac_address', 'location_name'
        device = Optopus::Device.where(:primary_mac_address => params['primary_mac_address']).where(:serial_number => params['serial_number']).first
        if device.nil?
          device = Optopus::Device.new(:serial_number => params['serial_number'], :primary_mac_address => params['primary_mac_address'])
          logger.info "New device found: #{device.serial_number} #{device.primary_mac_address}"
        end
        location = Optopus::Location.where(:common_name => params['location_name']).first
        if location.nil?
          location = Optopus::Location.new(:common_name => params['location_name'], :city => 'unknown', :state => 'unknown')
          logger.info "New location found: #{location.common_name}"
        end
        device.location = location
        device.bmc_ip_address = params.delete('bmc_ip_address')
        device.bmc_mac_address = params.delete('bmc_mac_address')
        device.model = params.delete('model')
        device.brand = params.delete('brand')
        device.switch_name = params.delete('switch_name')
        device.switch_port = params.delete('switch_port')
        device.save!
        status 202
      rescue ParamError => e
        status 400
        body({ :user_error => e.to_s }.to_json)
      rescue Exception => e
        status 500
        body({ :server_error => e.to_s }.to_json)
      end
    end

    # references can be passed in as a hash
    # ex: { 'username' => 'test' }
    put '/api/event' do
      begin
        type = nil
        message = nil
        references = nil
        case request.content_type
        when 'application/json'
          data = JSON.parse(request.body.read)
          type = data['type'] || 'generic'
          message = data['message']
          references = data['references']
        else
          validate_param_presence 'message'
          type = params['type'] || 'generic'
          message = params['message']
          # TODO: support references in non-json form
        end
        event = Optopus::Event.new(:message => message)
        event.type = type
        if references
          if references.include?('username')
            event.properties['user_username'] = references.delete('username')
          end
          if references.include?('hostname')
            event.properties['node_hostname'] = references.delete('hostname')
          end
        end
        event.save!
        status 201
      rescue Exception => e
        status 400
        body({:error => e.to_s})
      end
    end

    get '/api/events' do
      events = Optopus::Event.all.inject([]) do |events, event|
        events << {
          :message    => event.rendered_message,
          :type       => event.type,
          :id         => event.id,
          :created    => event.created_at,
          :references => event.references.inject([]) { |references, (type, reference)|
            references << { type => reference.to_h } if reference.respond_to?(:to_h)
          }
        }
      end
      body(events.to_json)
    end

    get '/api/nodes/active' do
      begin
        body(Optopus::Node.active.to_json)
      rescue Exception => e
        status 500
        body({ :server_error => e.to_s })
      end
    end

    get '/api/network/:id/next_ip' do
      begin
        network = Optopus::Network.find_by_id(params[:id])
        raise "no network with id #{params[:id]}" if network.nil?
        body({ :next_ip => network.available_ips.first }.to_json)
      rescue Exception => e
        status 404
        body({ :user_error => e.to_s }.to_json)
      end
    end

  end
end
