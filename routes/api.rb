module Inventory
  class App
    after '/api/*', :provides => :json do; end

    post '/api/appliance/register' do
      begin
        validate_param_precense 'serial_number', 'primary_mac_address'
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
