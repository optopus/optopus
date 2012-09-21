require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Optopus::Interface, '#new' do
  before(:all) do
    @node = Optopus::Node.create!(
      :hostname => 'test_interface',
      :serial_number => 'test_interface_serial',
      :primary_mac_address => '00:11:22:33:44:55',
      :virtual => false
    )
    @node2 = Optopus::Node.create!(
      :hostname => 'test_interface2',
      :serial_number => 'test_interface_serial2',
      :primary_mac_address => '00:11:22:33:44:52',
      :virtual => false
    )
  end

  it 'fails to save without an interface name or valid node id' do
    expect { Optopus::Interface.create! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'fails to save without a valid node id' do
    expect { Optopus::Interface.create!(:name => 'eth0') }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'saves successfully when supplied a valid name and node id' do
    @node.interfaces.create!(:name => 'eth0')
  end

  it 'fails to save when creating an interface with the same name and node id' do
    expect { @node.interfaces.create!(:name => 'eth0') }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'saves successfully when using the same interface name on a different node id' do
    @node2.interfaces.create!(:name => 'eth0')
  end

  after(:all) do
    @node.destroy
    @node2.destroy
  end
end

describe Optopus::Interface, '#destroy' do
  before(:all) do
    @node = Optopus::Node.create!(
      :hostname => 'test_interface',
      :serial_number => 'test_interface_serial',
      :primary_mac_address => '00:11:22:33:44:55',
      :virtual => false
    )
    @node2 = Optopus::Node.create!(
      :hostname => 'test_interface2',
      :serial_number => 'test_interface_serial2',
      :primary_mac_address => '00:11:22:33:44:52',
      :virtual => false
    )
  end

  it 'removes any interface connections' do
    interface1 = @node.interfaces.create!(:name => 'eth0')
    interface2 = @node2.interfaces.create!(:name => 'eth0')
    interface1.connections.create!(:target_interface => interface2)
    interface1.destroy
    interface2.reload
    interface2.connections.where(:target_interface_id => interface1.id).first.should be_nil
  end
end
