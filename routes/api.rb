module Optopus
  class App
    after '/api/*', :provides => :json do; end

    post '/api/appliance/register' do
      begin
        validate_param_precense 'serial_number', 'primary_mac_address'
        uuid = "#{params['serial_number'].downcase} #{params['primary_mac_address'].downcase}".to_md5_uuid
        appliance = Appliance.where(:uuid => uuid).first
        if appliance.nil?
          appliance = Appliance.new(:serial_number => params['serial_number'], :primary_mac_address => params['primary_mac_address'])
          logger.info "New appliance found: #{appliance.serial_number} #{appliance.primary_mac_address}"
        end
        appliance.bmc_ip_address = params.delete('bmc_ip_address')
        appliance.bmc_mac_address = params.delete('bmc_mac_address')
        appliance.model = params.delete('model')
        appliance.brand = params.delete('brand')
        appliance.switch_name = params.delete('switch_name')
        appliance.switch_port = params.delete('switch_port')
        appliance.save!
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
