require File.join(File.dirname(__FILE__), '..', 'spec_helper')
describe 'Optopus::Appliance#provisioned' do
  before(:all) do
    @valid_mac_address = '01:23:45:67:89:ad'
    @valid_ip_address = '10.10.10.10'
    @valid_serial_number = 'testserial4'
    @location = Optopus::Location.new(:common_name => 'test03')
  end

  it 'becomes true when a physical node is created with the same uuid' do
    appliance = Optopus::Appliance.new(:serial_number => @valid_serial_number, :primary_mac_address => @valid_mac_address)
    appliance.location = @location
    appliance.save!
    node = Optopus::Node.new(
      :hostname => 'test.host',
      :serial_number => @valid_serial_number,
      :primary_mac_address => @valid_mac_address,
      :virtual => false
    )
    node.save!
    appliance.reload
    appliance.provisioned.should == true
  end
end
