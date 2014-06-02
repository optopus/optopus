require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe 'Helpers' do
  subject do
    Class.new do
      include Optopus::AppHelpers::Main
      include Optopus::AppHelpers::Menu

      # Override is_authorized? to make these tests work
      # without seed data.
      def is_authorized?(role_name)
        role_name == 'admins'
      end
    end
  end

  before(:each) do
    @user = Optopus::User.find_by_username('crazed')
    @user = Optopus::User.new(:username => 'crazed')
    @roles = [Optopus::Role.new(:name => 'admins')]
    @user.stub(:roles).and_return(@roles)

    @subject = subject.new
    @subject.instance_variable_set '@user', @user
  end

  context 'Menu Helpers' do
    describe '#utility_menu_sections' do
      it 'can find utility menu sections' do
        # Set up sections and keep track of the original ones
        original_sections = Optopus::UtilityMenu.instance.sections.dup
        Optopus::UtilityMenu.instance.instance_variable_set('@sections', Array.new)
        section = Optopus::Menu::Section.new(:name => 'test menu2')
        Optopus::UtilityMenu.instance.register_section(section)

        # Make sure we return the section and restore original instance varible
        @subject.utility_menu_sections.should include(section)
        Optopus::UtilityMenu.instance.instance_variable_set '@sections', original_sections
      end
    end

    describe '#get_authorized_sections' do
      it 'find sections that the user is authororized for' do
        class TestMenu < Optopus::BaseMenu ; end
        section = Optopus::Menu::Section.new(:name => 'test menu', :required_role => 'admins')
        TestMenu.instance.register_section(section)
        @subject.get_authorized_sections(TestMenu.instance.sections).should include(section)
      end
    end

    describe '#profile_menu_sections' do
      it 'can find profile menu sections' do
        # Set up sections and keep track of the original ones
        original_sections = Optopus::ProfileMenu.instance.sections.dup
        Optopus::ProfileMenu.instance.instance_variable_set '@sections', Array.new
        section = Optopus::Menu::Section.new(:name => 'test menu2')
        Optopus::ProfileMenu.instance.register_section(section)

        # Make sure we return the section and restore original instance varible
        @subject.profile_menu_sections.should include(section)
        Optopus::ProfileMenu.instance.instance_variable_set('@sections', original_sections)
      end
    end
  end
end
