require File.join(File.dirname(__FILE__), '..','..','..','..','test','spec','spec_helper_plugin')
require File.join(File.dirname(__FILE__), '..', 'helper')
require 'mysql2'


describe PDNS::Client do
  before(:all) do
    PDNSHelper.set_up
    @mysql = PDNSHelper.create_client
    @client = Optopus::Plugin::PDNS.pdns_client
  end

  it 'should be able to create a domain' do
    domain = @client.create_domain('example.com')
    result = @mysql.query("SELECT name FROM domains WHERE id=#{domain['id']}").first
    domain['name'].should eq(result['name'])
  end

  it 'should fail to create a duplicate domain name' do
    expect { @client.create_domain('example.com') }.to raise_error(PDNS::DuplicateDomain)
  end

  it 'should be able to delete a domain' do
    domain = @client.domain_from_name('example.com')
    name = @client.delete_domain(domain['id'])
    domain['name'].should eq(name)
  end

  after(:all) do
    @mysql.close
    PDNSHelper.tear_down
  end
end
