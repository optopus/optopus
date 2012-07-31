module Optopus
  class App
    after '/api/*', :provides => :json do; end

    post '/api/node/register' do
      begin
        data = JSON.parse(request.body.read)
        hostname = data.delete('hostname')
        serial_number = data.delete('serial_number')
        primary_mac_address = data.delete('primary_mac_address')
        facts = data.delete('facts')
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
  end
end
