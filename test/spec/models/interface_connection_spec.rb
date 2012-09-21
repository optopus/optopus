require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Optopus::InterfaceConnection do
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
    @interface.connections.create!(:target_interface_id => @interface2.id)
  end

  it 'created the reverse connection successfully' do
    @interface2.reload
    @interface2.connections.where(:target_interface_id => @interface.id).first.should be
  end

  it 'fails to create a duplicate target_interface with scope source_interface' do
    expect { @interface.connections.create!(:target_interface => @interface2) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'destroys reverse connection when being destroyed' do
    connection = @interface.connections.first
    connection.destroy
    @interface2.reload
    @interface2.connections.first.should be_nil
  end

end
