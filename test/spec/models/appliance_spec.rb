require File.join(File.dirname(__FILE__), '..', 'spec_helper')
describe Appliance, '#new' do
  it 'fails to save without primary_mac_address' do
    appliance = Appliance.new(:serial_number => 'testserial')
    expect { appliance.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'fails to save without serial_number' do
    appliance = Appliance.new(:primary_mac_address => '01:23:45:67:89:ab')
    expect { appliance.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'saves successfully when supplied a serial_number and primary_mac_address' do
    appliance = Appliance.new(:serial_number => 'testserial', :primary_mac_address => '01:23:45:67:89:ab')
    appliance.save!
  end
end
