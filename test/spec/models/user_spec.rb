require File.join(File.dirname(__FILE__), '..', 'spec_helper')
describe Optopus::User, '#new' do
  before(:all) do
    @valid_username = 'afeid'
    @valid_display_name = 'Allan Feid'
  end

  it 'fails to save without username or display_name' do
    expect { Optopus::User.create! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'fails to save without display_name' do
    expect { Optopus::User.create!(:username => @valid_username) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'saves successfully with display_name and username' do
    Optopus::User.create!(:username => @valid_username, :display_name => @valid_display_name)
  end

  it 'fails to save with duplicate username' do
    expect { Optopus::User.create!(:username => @valid_username, :display_name => @valid_display_name) }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
