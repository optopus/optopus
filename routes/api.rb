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
        logger.error e.backtrace.join("\t\n")
        body({ :user_error => e.to_s }.to_json)
      end
    end

    post '/api/device/register' do
      begin
        validate_param_presence 'serial_number', 'primary_mac_address', 'location_name'
        primary_mac_address = params.delete('primary_mac_address').downcase.strip
        serial_number = params.delete('serial_number').downcase.strip
        location_name = params.delete('location_name').downcase.strip
        device = Optopus::Device.where(:primary_mac_address => primary_mac_address, :serial_number => serial_number).first
        if device.nil?
          device = Optopus::Device.new(:serial_number => serial_number, :primary_mac_address => primary_mac_address)
          logger.info "New device found: #{device.serial_number} #{device.primary_mac_address}"
        end
        location = Optopus::Location.where(:common_name => location_name).first
        if location.nil?
          location = Optopus::Location.new(:common_name => location_name, :city => 'unknown', :state => 'unknown')
          logger.info "New location found: #{location.common_name}"
        end
        device.location = location
        device.bmc_ip_address = params.delete('bmc_ip_address')
        device.bmc_mac_address = params.delete('bmc_mac_address')
        device.model = params.delete('model')
        device.brand = params.delete('brand')
        device.switch_name = params.delete('switch_name')
        device.switch_port = params.delete('switch_port')

        # Since this device is registering via our hardware image,
        # assume it is not provisioned.
        device.provisioned = false
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
        results = []
        hypervisors = Optopus::Hypervisor.search(:size => 1500) do
          fields 'libvirt.domains.name', :hostname
          query { string '*:*' }
        end
        node_lookup = {}
        node_lookup = hypervisors.inject({}) do |l, h|
          h['libvirt.domains.name'].each do |domain|
            l[domain] = h.hostname
          end
          l
        end
        Optopus::Node.active.includes(:pod).each do |node|
          data = {
            :hostname => node.hostname,
            :facts => node.facts,
            :properties => node.properties,
            :pod => node.pod ? node.pod.name : nil,
            :virtual => node.virtual,
            :created_at => node.created_at,
          }
          if node.virtual
            data[:hypervisor] = node_lookup[node.hostname]
          end
          results << { node.class.model_name.element => data }
        end
        body(results.to_json)
      rescue Exception => e
        status 500
        body({ :server_error => e.to_s })
      end
    end

    get '/api/network_nodes/active' do
      begin
        body(Optopus::NetworkNode.active.to_json)
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

    get '/api/search' do
      begin
        validate_param_presence 'string'
        options = Hash.new
        if params.include?('types')
          options[:types] = params['types'].split(',')
        end
        results = []
        Optopus::Search.query(params['string'], options).each do |result|
          result[:result_set].each do |item|
            results << item
          end
        end
        body({ :results => results }.to_json)
      rescue Exception => e
        status 400
        body({ :user_error => e.to_s }.to_json)
      end
    end

    get '/api/hypervisor_planner' do
      begin
        validate_param_presence 'cpus', 'ram', 'disk', 'location'
        raise 'CPUs must be higher than 0!' unless params['cpus'].to_i > 0
        raise 'RAM must be higher than 0!' unless params['ram'].to_i > 0
        raise 'Disk space must be higher than 0!' unless params['disk'].to_i > 0
        raise 'Location must be specified!' unless params['location'].to_s != 'Any'


        cpus = params['cpus'].to_i
        memory = params['ram'].to_i * 1024**3
        disk = params['disk'].to_i * 1024**3
        location = params['location']

        ranges = {
          'libvirt.free_disk' => { :gt => disk },
          'libvirt.node_free_cpus' => { :gt => cpus },
          'libvirt.node_free_memory' => { :gt => memory },
        }

        capable_hypervisors = Optopus::Hypervisor.capacity_search(ranges, location).sort { |a,b| a.hostname <=> b.hostname }

        # inject the similar vms into the result
        if params['name'].present?
          node_name = params['name']

          # parse the server_type out of the @node_name
          # this is if the user puts in "prod-ftp01" it'll return "ftp"
          n = node_name.match(/^(?:[^-]+-)?(.+?)(?:\d+)?$/)
          node_name = n[1] if n

          capable_hypervisors = capable_hypervisors.map do |h|
            h = h.to_hash
            similar_vms = hypervisor_domains_like(h, /#{node_name}/)
            nodes_on_switch_count = Optopus::Search.query("switch:#{ h[:switch] } hostname:*#{ node_name }*", :types => 'node').first.try(:[], :result_set)
            nodes_on_switch_count = nodes_on_switch_count.try(:count) || 0

            h['similar_vm_count'] = similar_vms.count
            h['similar_vm_for'] = params['name']
            h['similar_vms'] = similar_vms

            h['similar_vm_on_switch_count'] = nodes_on_switch_count

            h
          end
        end

        body(capable_hypervisors.to_json)
      end
    end

    # This will find nodes that are dependent on the given node
    get '/api/node/:name/children' do
      begin
        node = Optopus::Node.find_by_hostname(params[:name])
        raise "No node named '#{params[:name]}'" if node.nil?
        body({ :children => node.children.map {|n| n.hostname} }.to_json)
      rescue Exception => e
        logger.error e.to_s
        logger.error e.backtrace.join("\n\t")
        status 400
        body({ :user_error => e.to_s }.to_json)
      end
    end

    # Simplified output of all nodes for use with monitoring configs
    get '/api/nodes/monitoring' do
      output = Hash.new
      Optopus::Node.select("hostname, virtual, facts->'env' as env, facts->'monitoring' as monitoring").each do |node|
        data = node.attributes.dup
        data.delete('hostname')
        output[node.hostname] = data
      end
      output.to_json
    end

    get '/api/location_utilization' do
      begin
        location_data = Optopus::Hypervisor.resources_by_location
        keys = location_data.keys
        keys << "all"

        validate_param_presence 'location'
        raise "Location not specified!" unless params['location']
        raise "Unknown location!" unless params['location'].in? keys

        keys.each do |key|
          if key != 'all'
            location_data[key][:node_total_memory] *= 1024
            location_data[key][:node_cpus_utilization] = (location_data[key][:node_running_cpus].to_f / location_data[key][:node_total_cpus].to_f) * 100
            location_data[key][:node_memory_utilization] = ((location_data[key][:node_total_memory].to_f - location_data[key][:node_free_memory].to_f) / location_data[key][:node_total_memory].to_f) * 100
            location_data[key][:node_disk_utilization] = (location_data[key][:used_disk].to_f / (location_data[key][:used_disk].to_f + location_data[key][:free_disk].to_f)) * 100
          end
        end

        if params['location'] == 'all'
          body(location_data.to_json)
        else
          body(location_data[params['location']].to_json)
        end
      end
    end

    def update_interface(name, hostname, data)
      ip_address = data['ip_address']
      if ip_address.nil?
        raise 'Must supply ip_address'
      end
      begin
        IPAddr.new(ip_address)
      rescue Exception => e
        # Warn of invalid data
        logger.error("Invalid data for an interface: #{e}")
        return false
      end
      node = Optopus::Node.find_by_hostname(hostname)
      interface = node.interfaces.find_by_name(name) || Optopus::Interface.new(:name => name)
      node.interfaces << interface
      address = Optopus::Address.find_by_ip_address(ip_address) || Optopus::Address.new(:ip_address => ip_address)
      if interface.address != address
        interface.address = address
      end
      interface.save!
      true
    end

    post '/api/node/:hostname/interface/bulk_update' do
      begin
        data = JSON.parse(request.body.read)
        interfaces = data['interfaces']
        if interfaces.nil?
          raise 'Must supply interfaces!'
        end
        interfaces.each do |interface|
          update_interface(interface['name'], params[:hostname], interface)
        end
        nil
      rescue Exception => e
        logger.error(e.to_s)
        logger.error(e.backtrace.join("\t\n"))
        halt 400, { :error => e.to_s }.to_json
      end
    end

    post '/api/node/:hostname/interface/:interface' do
      begin
        data = JSON.parse(request.body.read)
        update_interface(params[:interface], params[:hostname], data)
      rescue Exception => e
        logger.error(e.to_s)
        logger.error(e.backtrace.join("\t\n"))
        halt 400, { :error => e.to_s }.to_json
      end
    end

    def update_network(data)
      cidr          = data['cidr']
      location_name = data['location']
      description   = data['description']
      vlan_id       = data['vlan_id']

      location = Optopus::Location.find_by_common_name(location_name)
      if location.nil?
        raise "Invalid location name #{location_name}"
      end

      network = Optopus::Network.find_by_address(cidr) || Optopus::Network.new(:address => cidr)
      network.location = location
      network.vlan_id = vlan_id if data.has_key?('vlan_id')
      network.description = description unless description.nil?
      network.save!
    end

    post '/api/networks/bulk_update' do
      begin
        data = JSON.parse(request.body.read)
        networks = data['networks']
        if networks.nil?
          raise 'Must supply networks!'
        end
        networks.each do |network|
          update_network(network)
        end
        nil
      rescue Exception => e
        logger.error(e.to_s)
        logger.error(e.backtrace.join("\t\n"))
        halt 400, { :error => e.to_s }.to_json
      end
    end

    post '/api/networks' do
      begin
        data = JSON.parse(request.body.read)
        update_network(data)
      rescue Exception => e
        logger.error(e.to_s)
        logger.error(e.backtrace.join("\t\n"))
        halt 400, { :error => e.to_s }.to_json
      end
    end

    get '/api/device/:serial' do
      device = Optopus::Device.where(:serial_number => params[:serial].downcase).to_json
    end

    get '/api/device/:serial/new' do
      device = Optopus::Device.where(:serial_number => params[:serial].downcase, :provisioned => false).to_json
    end

    get '/api/devices/:location/new' do
      location = Optopus::Location.find_by_common_name(params[:location])
      device = Optopus::Device.where(:location_id => location, :provisioned => false).to_json
    end
  end
end
