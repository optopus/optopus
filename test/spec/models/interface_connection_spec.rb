require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Optopus::InterfaceConnection, '#create' do
  before(:all) do
    @node = Optopus::Node.create!(
      :hostname => 'test_interface_conection',
      :serial_number => 'test_interface_conection_serial',
      :primary_mac_address => '00:15:22:33:44:55',
      :virtual => false
    )
    @node2 = Optopus::Node.create!(
      :hostname => 'test_interface_conection2',
      :serial_number => 'test_interface_conection_serial2',
      :primary_mac_address => '00:16:22:33:44:55',
      :virtual => false
    )
    @interface = @node.interfaces.create!(:name => 'eth0')
    @interface2 = @node2.interfaces.create!(:name => 'eth0')
  end

  it 'fails to create without a target_interface_id' do
    expect { Optopus::InterfaceConnection.create! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'creates successfully with a target_interface_id and source_interface_id' do
    Optopus::InterfaceConnection.create!(:source_interface => @interface, :target_interface => @interface2)
  end

  it 'fails to create a duplicate target_interface with scope source_interface' do
    expect { @interface.connections.create!(:target_interface => @interface2) }.to raise_error(ActiveRecord::RecordInvalid)
  end
end

describe Optopus::InterfaceConnection, '#save' do
end
