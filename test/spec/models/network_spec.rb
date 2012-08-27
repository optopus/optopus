require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Optopus::Network, '#new' do
  before(:all) do
    @valid_network = '10.0.1.0/23'
  end

  it 'fails to save without network address' do
    expect { Optopus::Network.create! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'saves successfully when supplied a network address' do
    Optopus::Network.create!(:address => @valid_network)
  end

  it 'fails to save when duplicate network is defined' do
    expect { Optopus::Network.create!(:address => @valid_network) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it 'associates lone addresses with network on save' do
    address = Optopus::Address.create!(:ip_address => '10.10.10.3')
    network = Optopus::Network.create!(:address => '10.10.10.0/24')
    network.addresses.first.id.should == address.id
  end
end

describe Optopus::Address, '#new' do
  before(:all) do
    @valid_address = '10.1.1.2'
    @address = Optopus::Address.new(:ip_address => @valid_address)
    @network = Optopus::Network.create!(:address => '10.1.1.0/23')
  end

  it 'fails to save without ip_address' do
    expect { Optopus::Address.create! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'saves successfully when supplied ip_address' do
    @address.save!
  end

  it 'associates with a valid network on save' do
    @address.network.id.should == @network.id
  end

  it 'fails to save when duplicate ip_address is defined' do
    expect { Optopus::Address.create!(:ip_address => @valid_address) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it 'fails to save if assigned network does not contain the assigned ip_address' do
    @address.reload
    @address.network = Optopus::Network.create!(:address => '192.168.1.0/24')
    expect { @address.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
