require File.join(File.dirname(__FILE__), '..', 'spec_helper')
describe Appliance, '#new' do
  before(:all) do
    @valid_mac_address = '01:23:45:67:89:ab'
    @valid_ip_address = '10.10.10.10'
    @valid_serial_number = 'testserial'
  end

  it 'fails to save without primary_mac_address' do
    appliance = Appliance.new(:serial_number => @valid_serial_number)
    expect { appliance.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'fails to save without serial_number' do
    appliance = Appliance.new(:primary_mac_address => @valid_mac_address)
    expect { appliance.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'saves successfully when supplied a serial_number and primary_mac_address' do
    appliance = Appliance.new(:serial_number => @valid_serial_number, :primary_mac_address => @valid_mac_address)
    appliance.save!
  end

  it 'fails to save when supplied the same serial_number and primary_mac_address' do
    appliance = Appliance.new(:serial_number => @valid_serial_number, :primary_mac_address => @valid_mac_address)
    expect { appliance.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
