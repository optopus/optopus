require File.join(File.dirname(__FILE__), '..', 'spec_helper')
describe Optopus::Device, '#new' do
  before(:all) do
    @valid_mac_address = '01:23:45:67:89:ab'
    @valid_ip_address = '10.10.10.10'
    @valid_serial_number = 'testserial'
    @test_location = Optopus::Location.new(:common_name => 'test01', :city => 'test', :state => 'NJ')
  end

  it 'fails to save without primary_mac_address' do
    device = Optopus::Device.new(:serial_number => @valid_serial_number)
    device.location = @test_location
    expect { device.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'fails to save without serial_number' do
    device = Optopus::Device.new(:primary_mac_address => @valid_mac_address)
    device.location = @test_location
    expect { device.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'saves successfully when supplied a serial_number, primary_mac_address, and location' do
    device = Optopus::Device.new(:serial_number => @valid_serial_number, :primary_mac_address => @valid_mac_address)
    device.location = @test_location
    device.save!
  end

  it 'fails to save when supplied the same serial_number and primary_mac_address' do
    device = Optopus::Device.new(:serial_number => @valid_serial_number, :primary_mac_address => @valid_mac_address)
    device.location = @test_location
    expect { device.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'fails to save without a valid location' do
    device = Optopus::Device.new(:serial_number => 'serial2', :primary_mac_address => '02:23:45:67:89:ab')
    expect { device.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
