require File.join(File.dirname(__FILE__), '..', 'spec_helper')
describe 'Optopus::Role and Optopus::User associations' do
  before(:all) do
    @user = Optopus::User.create(:username => 'crazed', :display_name => 'allan')
    @role = Optopus::Role.create(:name => 'admins')
  end

  it 'becomes associated successfully' do
    @user.roles << @role
    @user.save!
    @user.reload
    @user.roles.first.id.should == @role.id
  end
end
