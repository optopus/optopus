require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Optopus::Pod, '#new' do
  before(:all) do
    @location = Optopus::Location.create!(:common_name => 'pod_test', :city => 'test', :state => 'test')
    @location2 = Optopus::Location.create!(:common_name => 'pod_test2', :city => 'test', :state => 'test')
    @node = Optopus::Node.create!(
      :hostname => 'pod_test',
      :serial_number => 'pod_test',
      :primary_mac_address => '00:15:22:33:44:55',
      :virtual => false
    )
  end

  it 'fails to create without a name or location' do
    expect { Optopus::Pod.create! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'creates successfully with a location' do
    @location.pods.create!(:name => 'test_pod').should be
  end

  it 'fails to create a pod with the same name' do
    expect { @location.pods.create!(:name => 'test_pod') }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'creates successfully using the same name on a different location' do
    @location2.pods.create!(:name => 'test_pod').should be
  end

  it 'can be associated with nodes successfully' do
    pod = @location.pods.create!(:name => 'node_pod')
    pod.nodes << @node
    @node.reload
    @node.pod.should == pod
  end

  after(:all) do
    @location.destroy
    @node.destroy
  end
end
