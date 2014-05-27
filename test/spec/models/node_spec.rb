require File.join(File.dirname(__FILE__), '..', 'spec_helper')
describe Optopus::Node, '#new' do
  before(:all) do
    @valid_mac_address = '01:23:45:67:89:ac'
    @valid_ip_address = '10.10.10.10'
    @valid_serial_number = 'testserial2'
    @hostname = 'test5.host'
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
    node = Optopus::Node.where("facts @> 'id=>crazed'").first
    node.id.should == @node.id
  end
end

describe Optopus::Node, '#save' do
  before(:all) do
    @valid_interfaces = [ 'em1', 'eth0', 'eth1', 'lo0', 'ge-0/0/1', 'GigabitEthernet1' ]
    @node = Optopus::Node.create!(
      :hostname => 'interface_fact_test',
      :serial_number => 'interface_fact_test',
      :primary_mac_address => '01:02:04:44:04:06',
      :virtual => true
    )
    @valid_ip_address = '172.16.200.20'
  end

  it 'creates new interfaces based off the interfaces key of facts' do
    @node.facts['interfaces'] = @valid_interfaces.join(',')
    @node.save!
    @node.reload
    @node.interfaces.map { |i| i.name }.sort.should == @valid_interfaces.sort
  end

  it 'destroys interfaces that are no longer part of the interfaces key of facts' do
    new_interfaces = @valid_interfaces - @valid_interfaces.last(2)
    @node.facts['interfaces'] = new_interfaces.join(',')
    @node.save!
    @node.reload
    @node.interfaces.map { |i| i.name }.sort.should == new_interfaces.sort
  end

  it 'creates an ipaddress when facts["ipaddress_eth0"] is present' do
    @node.facts['ipaddress_eth0'] = @valid_ip_address
    @node.save!
    @node.reload
    @node.interfaces.where(:name => 'eth0').first.address.ip_address.should == @valid_ip_address
  end
end
