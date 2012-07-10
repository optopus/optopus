require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Optopus::App, 'POST /api/node/register' do
  include Rack::Test::Methods

  before(:all) do
    @valid_mac_address = '01:23:45:67:89:ab'
    @valid_ip_address = '10.10.10.10'
    @valid_serial_number = 'testserial'
    @valid_model = 'PowerEdge R510'
    @valid_brand = 'Dell'
    @valid_switch_name = 'testswitch'
    @valid_switch_port = 'ge-0/0/0'
    @location_name = 'test03'
    @node_uuid = "#{@valid_serial_number} #{@valid_mac_address}".to_md5_uuid
  end

  it 'returns a 400 when invalid posting invalid JSON' do
    post '/api/node/register', 'invalid'
    last_response.status.should == 400
  end

  it 'returns a 400 when missing virtual' do
    data = { :primary_mac_address => @valid_mac_address, :serial_number => @valid_serial_number, :hostname => 'test.host' }
    post '/api/node/register', data.to_json
    last_response.status.should == 400
  end

  it 'returns a 400 when missing serial_number' do
    data = { :virtual => true, :primary_mac_address => @valid_mac_address, :hostname => 'test.host' }
    post '/api/node/register', data.to_json
    last_response.status.should == 400
  end

  it 'returns a 400 when missing primary_mac_address' do
    data = { :virtual => true, :serial_number => @valid_serial_number, :hostname => 'test.host' }
    post '/api/node/register', data.to_json
    last_response.status.should == 400
  end

  it 'returns a 400 when missing hostname' do
    data = { :virtual => true, :primary_mac_address => @valid_primary_mac_address }
    post '/api/node/register', data.to_json
    last_response.status.should == 400
  end

  it 'returns a 202 when supplied virtual, primary_mac_address, serial_number, and hostname' do
    data = { :virtual => true, :primary_mac_address => @valid_mac_address, :serial_number => @valid_serial_number, :hostname => 'test.host' }
    post '/api/node/register', data.to_json
    last_response.status.should == 202
  end

  it 'updates a node hostname' do
    data = { :virtual => true, :primary_mac_address => @valid_mac_address, :serial_number => @valid_serial_number, :hostname => 'test2.host' }
    post '/api/node/register', data.to_json
    last_response.status.should == 202
    Optopus::Node.where(:uuid => @node_uuid).first.hostname == data[:hostname]
  end
end

describe Optopus::App, 'POST /api/appliance/register' do
  include Rack::Test::Methods

  before(:all) do
    @valid_mac_address = '01:23:45:67:89:ab'
    @valid_ip_address = '10.10.10.10'
    @valid_serial_number = 'testserial'
    @valid_model = 'PowerEdge R510'
    @valid_brand = 'Dell'
    @valid_switch_name = 'testswitch'
    @valid_switch_port = 'ge-0/0/0'
    @location_name = 'test03'
    @appliance_uuid = "#{@valid_serial_number} #{@valid_mac_address}".to_md5_uuid
  end

  it 'returns a 400 when no parameters are supplied' do
    post '/api/appliance/register'
    last_response.status.should == 400
  end

  it 'returns a 400 when missing primary_mac_address' do
    post '/api/appliance/register', { 'serial_number' => @valid_serial_number }
    last_response.status.should == 400
  end

  it 'returns a 400 when missing serial_number' do
    post '/api/appliance/register', { 'primary_mac_address' => @valid_mac_address }
    last_response.status.should == 400
  end

  it 'returns a 202 when serial_number, primary_mac_address, and location_name are supplied' do
    params = {
      'serial_number' => @valid_serial_number,
      'primary_mac_address' => @valid_mac_address,
      'location_name' => @location_name,
    }
    post '/api/appliance/register', params
    last_response.status.should == 202
  end

  it 'updates an appliance with bmc_ip_address' do
    params = {
      'serial_number' => @valid_serial_number,
      'primary_mac_address' => @valid_mac_address,
      'location_name' => @location_name,
      'bmc_ip_address' => @valid_ip_address,
    }
    post '/api/appliance/register', params
    last_response.status.should == 202
    Optopus::Appliance.where(:uuid => @appliance_uuid).first.bmc_ip_address.should == @valid_ip_address
  end

  it 'updates an appliance with bmc_mac_address' do
    params = {
      'serial_number' => @valid_serial_number,
      'primary_mac_address' => @valid_mac_address,
      'location_name' => @location_name,
      'bmc_mac_address' => @valid_mac_address,
    }
    post '/api/appliance/register', params
    last_response.status.should == 202
    Optopus::Appliance.where(:uuid => @appliance_uuid).first.bmc_mac_address.should == @valid_mac_address
  end

  it 'updates an appliance with model' do
    params = {
      'serial_number' => @valid_serial_number,
      'primary_mac_address' => @valid_mac_address,
      'location_name' => @location_name,
      'model' => @valid_model,
    }
    post '/api/appliance/register', params
    last_response.status.should == 202
    Optopus::Appliance.where(:uuid => @appliance_uuid).first.model.should == @valid_model
  end

  it 'updates an appliance with brand' do
    params = {
      'serial_number' => @valid_serial_number,
      'primary_mac_address' => @valid_mac_address,
      'location_name' => @location_name,
      'brand' => @valid_brand,
    }
    post '/api/appliance/register', params
    last_response.status.should == 202
    Optopus::Appliance.where(:uuid => @appliance_uuid).first.brand.should == @valid_brand
  end

  it 'updates an appliance with switch_name' do
    params = {
      'serial_number' => @valid_serial_number,
      'primary_mac_address' => @valid_mac_address,
      'location_name' => @location_name,
      'switch_name' => @valid_switch_name,
    }
    post '/api/appliance/register', params
    last_response.status.should == 202
    Optopus::Appliance.where(:uuid => @appliance_uuid).first.switch_name.should == @valid_switch_name
  end

  it 'updates an appliance with switch_port' do
    params = {
      'serial_number' => @valid_serial_number,
      'primary_mac_address' => @valid_mac_address,
      'location_name' => @location_name,
      'switch_port' => @valid_switch_port,
    }
    post '/api/appliance/register', params
    last_response.status.should == 202
    Optopus::Appliance.where(:uuid => @appliance_uuid).first.switch_port.should == @valid_switch_port
  end
end
