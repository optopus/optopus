require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Inventory::App, 'POST /api/appliance/register' do
  include Rack::Test::Methods

  before(:all) do
    @valid_mac_address = '01:23:45:67:89:ab'
    @valid_ip_address = '10.10.10.10'
    @valid_serial_number = 'testserial'
    @valid_model = 'PowerEdge R510'
    @valid_brand = 'Dell'
    @valid_switch_name = 'testswitch'
    @valid_switch_port = 'ge-0/0/0'
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

  it 'returns a 202 when serial_number and primary_mac_address are supplied' do
    post '/api/appliance/register', { 'serial_number' => @valid_serial_number, 'primary_mac_address' => @valid_mac_address }
    last_response.status.should == 202
  end

  it 'updates an appliance with bmc_ip_address' do
    params = {
      'serial_number' => @valid_serial_number,
      'primary_mac_address' => @valid_mac_address,
      'bmc_ip_address' => @valid_ip_address,
    }
    post '/api/appliance/register', params
    last_response.status.should == 202
    Appliance.where(:uuid => @appliance_uuid).first.bmc_ip_address.should == @valid_ip_address
  end

  it 'updates an appliance with bmc_mac_address' do
    params = {
      'serial_number' => @valid_serial_number,
      'primary_mac_address' => @valid_mac_address,
      'bmc_mac_address' => @valid_mac_address,
    }
    post '/api/appliance/register', params
    last_response.status.should == 202
    Appliance.where(:uuid => @appliance_uuid).first.bmc_mac_address.should == @valid_mac_address
  end

  it 'updates an appliance with model' do
    params = {
      'serial_number' => @valid_serial_number,
      'primary_mac_address' => @valid_mac_address,
      'model' => @valid_model,
    }
    post '/api/appliance/register', params
    last_response.status.should == 202
    Appliance.where(:uuid => @appliance_uuid).first.model.should == @valid_model
  end

  it 'updates an appliance with brand' do
    params = {
      'serial_number' => @valid_serial_number,
      'primary_mac_address' => @valid_mac_address,
      'brand' => @valid_brand,
    }
    post '/api/appliance/register', params
    last_response.status.should == 202
    Appliance.where(:uuid => @appliance_uuid).first.brand.should == @valid_brand
  end

  it 'updates an appliance with switch_name' do
    params = {
      'serial_number' => @valid_serial_number,
      'primary_mac_address' => @valid_mac_address,
      'switch_name' => @valid_switch_name,
    }
    post '/api/appliance/register', params
    last_response.status.should == 202
    Appliance.where(:uuid => @appliance_uuid).first.switch_name.should == @valid_switch_name
  end

  it 'updates an appliance with switch_port' do
    params = {
      'serial_number' => @valid_serial_number,
      'primary_mac_address' => @valid_mac_address,
      'switch_port' => @valid_switch_port,
    }
    post '/api/appliance/register', params
    last_response.status.should == 202
    Appliance.where(:uuid => @appliance_uuid).first.switch_port.should == @valid_switch_port
  end
end
