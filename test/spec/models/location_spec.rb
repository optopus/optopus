require File.join(File.dirname(__FILE__), '..', 'spec_helper')
describe Optopus::Location, '#new' do
  before(:all) do
    @common_name = 'ma01'
    @city = 'Boston'
    @state = 'MA'
  end

  it 'fails to save without common_name' do
    location = Optopus::Location.new
    expect { location.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'saves successfully with common_name, city and state' do
    location = Optopus::Location.new(:common_name => @common_name, :city => @city, :state => @state)
    location.save!
  end

  it 'ensures unique common_name field' do
    location = Optopus::Location.new(:common_name => @common_name, :city => @city, :state => @state)
    expect { location.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
