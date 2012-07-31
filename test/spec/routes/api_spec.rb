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
  end

  it 'returns a 400 when invalid posting invalid JSON' do
    post '/api/node/register', 'invalid'
    last_response.status.should == 400
  end

  it 'returns a 400 when missing virtual' do
    data = { :primary_mac_address => @valid_mac_address, :serial_number => @valid_serial_number, :hostname => 'test3.host' }
    post '/api/node/register', data.to_json
    last_response.status.should == 400
  end

  it 'returns a 400 when missing serial_number' do
    data = { :virtual => true, :primary_mac_address => @valid_mac_address, :hostname => 'test3.host' }
    post '/api/node/register', data.to_json
    last_response.status.should == 400
  end

  it 'returns a 400 when missing primary_mac_address' do
    data = { :virtual => true, :serial_number => @valid_serial_number, :hostname => 'test3.host' }
    post '/api/node/register', data.to_json
    last_response.status.should == 400
  end

  it 'returns a 400 when missing hostname' do
    data = { :virtual => true, :primary_mac_address => @valid_primary_mac_address }
    post '/api/node/register', data.to_json
    last_response.status.should == 400
  end

  it 'returns a 202 when supplied virtual, primary_mac_address, serial_number, and hostname' do
    data = { :virtual => true, :primary_mac_address => @valid_mac_address, :serial_number => @valid_serial_number, :hostname => 'test31.host' }
    post '/api/node/register', data.to_json
    last_response.status.should == 202
  end

  it 'updates a node hostname' do
    data = { :virtual => true, :primary_mac_address => @valid_mac_address, :serial_number => @valid_serial_number, :hostname => 'test14.host' }
    post '/api/node/register', data.to_json
    last_response.status.should == 202
    Optopus::Node.where(:primary_mac_address => @valid_mac_address).first.hostname == data[:hostname]
  end
end

describe Optopus::App, 'POST /api/device/register' do
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
  end

  it 'returns a 400 when no parameters are supplied' do
    post '/api/device/register'
    last_response.status.should == 400
  end

  it 'returns a 400 when missing primary_mac_address' do
    post '/api/device/register', { 'serial_number' => @valid_serial_number }
    last_response.status.should == 400
  end

  it 'returns a 400 when missing serial_number' do
    post '/api/device/register', { 'primary_mac_address' => @valid_mac_address }
    last_response.status.should == 400
  end

  it 'returns a 202 when serial_number, primary_mac_address, and location_name are supplied' do
    params = {
      'serial_number' => @valid_serial_number,
      'primary_mac_address' => @valid_mac_address,
      'location_name' => @location_name,
    }
    post '/api/device/register', params
    last_response.status.should == 202
  end

  it 'updates an device with bmc_ip_address' do
    params = {
      'serial_number' => @valid_serial_number,
      'primary_mac_address' => @valid_mac_address,
      'location_name' => @location_name,
      'bmc_ip_address' => @valid_ip_address,
    }
    post '/api/device/register', params
    last_response.status.should == 202
    Optopus::Device.where(:primary_mac_address => @valid_mac_address).first.bmc_ip_address.should == @valid_ip_address
  end

  it 'updates an device with bmc_mac_address' do
    params = {
      'serial_number' => @valid_serial_number,
      'primary_mac_address' => @valid_mac_address,
      'location_name' => @location_name,
      'bmc_mac_address' => @valid_mac_address,
    }
    post '/api/device/register', params
    last_response.status.should == 202
    Optopus::Device.where(:primary_mac_address => @valid_mac_address).first.bmc_mac_address.should == @valid_mac_address
  end

  it 'updates an device with model' do
    params = {
      'serial_number' => @valid_serial_number,
      'primary_mac_address' => @valid_mac_address,
      'location_name' => @location_name,
      'model' => @valid_model,
    }
    post '/api/device/register', params
    last_response.status.should == 202
    Optopus::Device.where(:primary_mac_address => @valid_mac_address).first.model.should == @valid_model
  end

  it 'updates an device with brand' do
    params = {
      'serial_number' => @valid_serial_number,
      'primary_mac_address' => @valid_mac_address,
      'location_name' => @location_name,
      'brand' => @valid_brand,
    }
    post '/api/device/register', params
    last_response.status.should == 202
    Optopus::Device.where(:primary_mac_address => @valid_mac_address).first.brand.should == @valid_brand
  end

  it 'updates an device with switch_name' do
    params = {
      'serial_number' => @valid_serial_number,
      'primary_mac_address' => @valid_mac_address,
      'location_name' => @location_name,
      'switch_name' => @valid_switch_name,
    }
    post '/api/device/register', params
    last_response.status.should == 202
    Optopus::Device.where(:primary_mac_address => @valid_mac_address).first.switch_name.should == @valid_switch_name
  end

  it 'updates an device with switch_port' do
    params = {
      'serial_number' => @valid_serial_number,
      'primary_mac_address' => @valid_mac_address,
      'location_name' => @location_name,
      'switch_port' => @valid_switch_port,
    }
    post '/api/device/register', params
    last_response.status.should == 202
    Optopus::Device.where(:primary_mac_address => @valid_mac_address).first.switch_port.should == @valid_switch_port
  end
end
