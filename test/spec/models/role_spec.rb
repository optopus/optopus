require File.join(File.dirname(__FILE__), '..', 'spec_helper')
describe Optopus::Role, '#new' do
  before(:all) do
    @valid_name = 'admin'
  end

  it 'fails to save without name' do
    expect { Optopus::Role.create! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'saves successfully with name' do
    Optopus::Role.create!(:name => @valid_name)
  end

  it 'fails to save with duplicate name' do
    expect { Optopus::Role.create!(:name => @valid_name) }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
