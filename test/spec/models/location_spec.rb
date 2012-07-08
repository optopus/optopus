require File.join(File.dirname(__FILE__), '..', 'spec_helper')
describe Optopus::Location, '#new' do
  before(:all) do
    @common_name = 'ma01'
  end

  it 'fails to save without common_name' do
    location = Optopus::Location.new
    expect { location.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'saves successfully with common_name' do
    location = Optopus::Location.new(:common_name => @common_name)
    location.save!
  end

  it 'ensures unique common_name field' do
    location = Optopus::Location.new(:common_name => @common_name)
    expect { location.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
