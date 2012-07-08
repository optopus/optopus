require File.join(File.dirname(__FILE__), '..', 'spec_helper')
describe Optopus::Node, '#new' do
  before(:all) do
    @valid_mac_address = '01:23:45:67:89:ac'
    @valid_ip_address = '10.10.10.10'
    @valid_serial_number = 'testserial2'
  end

  it 'fails to save without primary_mac_address' do
    node = Optopus::Node.new(:serial_number => @valid_serial_number)
    expect { node.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'fails to save without serial_number' do
    node = Optopus::Node.new(:primary_mac_address => @valid_mac_address)
    expect { node.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'saves successfully when supplied a serial_number and primary_mac_address' do
    node = Optopus::Node.new(:serial_number => @valid_serial_number, :primary_mac_address => @valid_mac_address)
    node.save!
  end

  it 'fails to save when supplied the same serial_number and primary_mac_address' do
    node = Optopus::Node.new(:serial_number => @valid_serial_number, :primary_mac_address => @valid_mac_address)
    expect { node.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
