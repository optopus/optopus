require File.join(File.dirname(__FILE__), '..', 'spec_helper')
describe Optopus::Appliance, '#new' do
  before(:all) do
    @valid_mac_address = '01:23:45:67:89:ab'
    @valid_ip_address = '10.10.10.10'
    @valid_serial_number = 'testserial'
    @test_location = Optopus::Location.new(:common_name => 'test01', :city => 'test', :state => 'NJ')
  end

  it 'fails to save without primary_mac_address' do
    appliance = Optopus::Appliance.new(:serial_number => @valid_serial_number)
    appliance.location = @test_location
    expect { appliance.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'fails to save without serial_number' do
    appliance = Optopus::Appliance.new(:primary_mac_address => @valid_mac_address)
    appliance.location = @test_location
    expect { appliance.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'saves successfully when supplied a serial_number, primary_mac_address, and location' do
    appliance = Optopus::Appliance.new(:serial_number => @valid_serial_number, :primary_mac_address => @valid_mac_address)
    appliance.location = @test_location
    appliance.save!
  end

  it 'fails to save when supplied the same serial_number and primary_mac_address' do
    appliance = Optopus::Appliance.new(:serial_number => @valid_serial_number, :primary_mac_address => @valid_mac_address)
    appliance.location = @test_location
    expect { appliance.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'fails to save without a valid location' do
    appliance = Optopus::Appliance.new(:serial_number => 'serial2', :primary_mac_address => '02:23:45:67:89:ab')
    expect { appliance.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
