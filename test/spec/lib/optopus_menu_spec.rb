require 'optopus/menu'

class TestMenu < Optopus::BaseMenu ; end

describe 'Optopus::BaseMenu' do
  after(:each) do
    # Make sure we reset the menu to empty after every test
    TestMenu.instance.instance_variable_set '@sections', Array.new
  end

  it 'can register new sections' do
    section = Optopus::Menu::Section.new(:name => 'super menu')
    TestMenu.instance.register_section(section)
    TestMenu.instance.sections.should include(section)
  end
end

describe 'Optopus::Menu::Section' do
  context '#new' do
    it 'can successfully be initialized' do
      section = Optopus::Menu::Section.new(:name => 'super menu')
      section.name.should == 'super menu'
    end
  end

  context '#add_link' do
    before(:each) do
      @section = Optopus::Menu::Section.new(:name => 'test')
    end

    it 'raises an error when missing required options' do
      expect { @section.add_link() }.to raise_error RuntimeError
      expect { @section.add_link(:display => 'display') }.to raise_error RuntimeError
      expect { @section.add_link(:href => 'href') }.to raise_error RuntimeError
    end

    it 'can add a new link properly' do
      link = { :display => 'test_display', :href => 'test_href' }
      @section.add_link(link)
      @section.links.should include(link)
    end
  end
end
