require File.join(File.dirname(__FILE__), '..', 'spec_helper')
describe 'Optopus::Node and Optopus::Device associations' do
  before(:all) do
    @valid_mac_address = '01:23:45:67:89:ad'
    @valid_ip_address = '10.10.10.10'
    @valid_serial_number = 'testserial3'
    @location = Optopus::Location.new(:common_name => 'test02', :city => 'test', :state => 'TX')
  end

  it 'physical node becomes associated with device on creation when matching uuid is found' do
    device = Optopus::Device.new(:serial_number => @valid_serial_number, :primary_mac_address => @valid_mac_address)
    device.location = @location
    device.save!
    node = Optopus::Node.new(
      :hostname => 'test.host',
      :serial_number => @valid_serial_number,
      :primary_mac_address => @valid_mac_address,
      :virtual => false
    )
    node.save!
    node.device_id.should == device.id
  end
end
