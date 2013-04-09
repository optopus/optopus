require File.join(File.dirname(__FILE__), '..','..','..','..','test','spec','spec_helper_plugin')
require File.join(File.dirname(__FILE__), '..', 'helper')

describe Optopus::Plugin::PDNS, '#node_listener' do
  before(:all) do
    PDNSHelper.set_up
    @mysql = PDNSHelper.create_client
    @client = Optopus::Plugin::PDNS.pdns_client
    @arp_domain = "10.in-addr.arpa"
    @domain = "da01.com"
    @mysql.query("insert into domains set name = '#{@arp_domain}', type = 'NATIVE';")
    @mysql.query("insert into domains set name = '#{@domain}', type = 'NATIVE';")
    @mysql.query("insert into zones set domain_id = (select id from domains where name = '#{@arp_domain}' limit 1), owner = 1, zone_templ_id = 1")
    @mysql.query("insert into zones set domain_id = (select id from domains where name = '#{@domain}' limit 1), owner = 1, zone_templ_id = 1")

    facts = { 
      "ipaddress"    => "10.10.100.100", 
      "fqdn"         => "testhost.#{@domain}",
      "serialnumber" => "not specified",
      "macaddress"   => "11:22:33:44:55:66",
      "domain"       => "#{@domain}"
    }
    @node = Optopus::Node.create(
      :hostname => facts['fqdn'],
      :virtual => true,
      :facts => facts,
      :active => true
    )
    @node.serial_number = facts['serialnumber'].downcase.strip unless facts['serialnumber'].nil?
    @node.primary_mac_address = facts['macaddress'].downcase.strip
  end

  it 'should create both an A and PTR record when hostname and ipaddress do not exist in PDNS' do 
    @node.save!
    @node.reload
    @node.facts['ipaddress'].should == @client.record_from_hostname(@node.hostname)['content']
    @node.hostname.should == @client.record_from_hostname(@node.facts['ipaddress'].split(".",4).reverse.join('.') + ".in-addr.arpa","PTR")['content']
  end

  it 'should update the A and PTR record when IP changes, but hostname remains the same' do
    @node.facts['ipaddress'] = "10.10.200.200"
    @node.save!
    @node.reload
    @node.facts['ipaddress'].should == "10.10.200.200"
    @node.facts['ipaddress'].should == @client.record_from_hostname(@node.hostname)['content']
    @node.hostname.should == @client.record_from_hostname(@node.facts['ipaddress'].split(".",4).reverse.join('.') + ".in-addr.arpa","PTR")['content']
  end

  it "should not insert A records when ip address of node already exists in pdns, and will log event" do
    facts = { 
      "ipaddress"    => "10.10.200.200", 
      "fqdn"         => "failing.#{@domain}",
      "serialnumber" => "not specified",
      "macaddress"   => "11:22:33:44:55:77",
      "domain"       => "#{@domain}"
    }
    node = Optopus::Node.create(
      :hostname => facts['fqdn'],
      :virtual => true,
      :facts => facts,
      :active => true
    )
    node.serial_number = facts['serialnumber'].downcase.strip unless facts['serialnumber'].nil?
    node.primary_mac_address = facts['macaddress'].downcase.strip
    node.save!
    node.reload
    @client.record_from_hostname(node.hostname).should == nil
    Optopus::Event.where("properties -> 'node_id' = '#{node.id}' and properties -> 'event_type' = 'dns_update_failed'").first['message'].should == "The node '#{node.hostname}' has an ip of '#{node.facts['ipaddress']}, which already exists in the records table. dns update failed"
  end

  it "should notify only when a node checks in with a domain name that does not exist as a zone, and will log an event" do
    facts = { 
      "ipaddress"    => "10.10.140.14", 
      "fqdn"         => "host.baddomain.com",
      "serialnumber" => "not specified",
      "macaddress"   => "11:22:33:44:55:77",
      "domain"       => "baddomain.com"
    }
    node = Optopus::Node.create(
      :hostname => facts['fqdn'],
      :virtual => true,
      :facts => facts,
      :active => true
    )
    node.serial_number = facts['serialnumber'].downcase.strip unless facts['serialnumber'].nil?
    node.primary_mac_address = facts['macaddress'].downcase.strip
    node.save!
    node.reload
    @client.record_from_hostname(node.hostname).should == nil
    Optopus::Event.where("properties -> 'node_id' = '#{node.id}' and properties -> 'event_type' = 'dns_update_failed'").first['message'].should == "The node '#{node.hostname}' does not belong to a domain in PDNS"
  end

  after(:all) do
    @mysql.close
    PDNSHelper.tear_down
  end
end
