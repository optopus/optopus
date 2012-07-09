require File.join(File.dirname(__FILE__), '..', 'spec_helper')
describe Optopus::Node, '#new' do
  before(:all) do
    @valid_mac_address = '01:23:45:67:89:ac'
    @valid_ip_address = '10.10.10.10'
    @valid_serial_number = 'testserial2'
    @hostname = 'test.host'
  end

  it 'fails to save without primary_mac_address' do
    node = Optopus::Node.new(:serial_number => @valid_serial_number, :hostname => @hostname)
    expect { node.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'fails to save without serial_number' do
    node = Optopus::Node.new(:primary_mac_address => @valid_mac_address)
    expect { node.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'fails to save without virtual' do
    node = Optopus::Node.new(:primary_mac_address => @valid_mac_address, :serial_number => @valid_serial_number)
    expect { node.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'saves successfully when supplied a serial_number, primary_mac_address, and virtual' do
    node = Optopus::Node.new(
      :hostname => @hostname,
      :serial_number => @valid_serial_number,
      :primary_mac_address => @valid_mac_address,
      :virtual => false
    )
    node.save!
  end

  it 'fails to save when supplied the same serial_number and primary_mac_address' do
    node = Optopus::Node.new(
      :hostname => @hostname,
      :serial_number => @valid_serial_number,
      :primary_mac_address => @valid_mac_address,
      :virtual => false
    )
    expect { node.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end
end

describe Optopus::Node, '#facts' do
  before(:all) do
    @facts = {
      'architecture' => 'x86_64',
      'domain' => 'home',
      'fqdn' => 'air.home',
      'hardwareisa' => 'i386',
      'hardwaremodel' => 'x86_64',
      'hostname' => 'air',
      'id' => 'crazed',
      'interfaces' => 'lo0,gif0,stf0,en0,p2p0',
      'ipaddress' => '192.168.1.4',
    }
    @node = Optopus::Node.create(
      :hostname => 'facttest',
      :serial_number => 'testtest',
      :primary_mac_address => '01:02:04:04:04:06',
      :virtual => true
    )
  end

  it 'inserts artbitrary key => value items into facts' do
    @node.facts = @facts
    @node.save!
    @node.reload
    @node.facts.should == @facts
  end

  it 'can query for facts previously inserted' do
    node = Optopus::Node.where("facts @> (:key => :value)", :key => 'id', :value => 'crazed').first
    node.uuid.should == @node.uuid
  end
end
