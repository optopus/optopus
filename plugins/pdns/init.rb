require 'optopus/plugin'
require 'ipaddr'

require_relative 'lib/pdns/client'
module Optopus
  module Plugin
    module PDNS
      extend Optopus::Plugin

      module DNSRecordUtils

        def has_a_record?
          !a_record.nil?
        end

        def has_correct_a_record?
          record = a_record
          record.nil? ? false : record['content'] == self.facts['ipaddress']
        end

        def has_ptr_record?
          !ptr_record.nil?
        end

        def a_record
          pdns_client.record_from_hostname(self.hostname)
        end

        def ptr_record
          pdns_client.record_from_content(self.hostname, 'PTR')
        end

        def set_ptr_record!
          ip = IPAddr.new(self.facts['ipaddress'])
          record = ptr_record

          if record.nil?
            # TODO: this needs to be configurable, basically we take
            # 117.2.8.10.in-addr.arpa and turn it into 10.in-addr.arpa as the reverse dns zone
            domain = pdns_client.domain_from_name(ip.reverse.split('.').last(3).join('.'))
            pdns_client.create_record(
              :domain_id => domain['id'].to_s,
              :name      => ip.reverse,
              :type      => 'PTR',
              :content   => self.hostname,
              :ttl       => '600'
            )
          else
            pdns_client.update_record(record['id'], :name => ip.reverse)
          end
          nil
        end

        def set_a_record!
          record = a_record
          if record.nil?
            domain = pdns_client.domain_from_name(self.facts['domain'])
            if domain
              pdns_client.create_record(
                :domain_id => domain['id'].to_s,
                :name      => self.hostname,
                :type      => 'A',
                :content   => self.facts['ipaddress'],
                :ttl       => '600'
              )
            end
          else
            pdns_client.update_record(record['id'], :content => self.facts['ipaddress'])
          end
          nil
        end

        private

        def pdns_client
          @pdns_client ||= Optopus::Plugin::PDNS.pdns_client
        end
      end

      class NodeObserver < ActiveRecord::Observer
        observe Optopus::Node

        def after_save(node)
          # If this is a network node, skip it.
          return if node.is_a?(Optopus::NetworkNode)

          hostname_array      = node.hostname.split(".",2)
          pdns_client         = Optopus::Plugin::PDNS.pdns_client
          autoupdate_settings = Optopus::Plugin::PDNS.autoupdate_settings
          hostname_regex      = Regexp.new(autoupdate_settings['hostname_regex'])

          # A record data
          ip_record       = pdns_client.record_from_content(node.facts['ipaddress'])
          hostname_record = pdns_client.record_from_hostname(node.hostname)

          # PTR record data for checks
          ptr_address     = node.facts['ipaddress'].split(".",4).reverse.join('.') + ".in-addr.arpa"
          ptr_host_record = pdns_client.record_from_content(node.hostname, 'PTR')
          ptr_ip_record   = pdns_client.record_from_hostname(ptr_address, 'PTR')

          ## force admins to manually create/update dns for Docker nodes or anything with a tunnel device
          ## Only do this if there's no record for this hostname already
          if !hostname_record && node.facts['interfaces'] && node.facts['interfaces'].include?("tun") or node.facts['interfaces'].include?("docker")
            #event = Optopus::Event.new
            #event.message = "The node '#{node.hostname}/(#{node.facts['ipaddress']})' has an unsupported interface. Please create this record manually."
            #event.type = 'dns_create_failed'
            #event.properties['node_id'] = node.id
            #event.save!
            return
          end

          # Force a check of PTR records; for now, just see if they match our data.
          # If not, delete them, and we'll create them below.
          if ptr_host_record && ptr_ip_record

            # If we have an IP record but no host record, nuke it
            if ptr_ip_record && !ptr_host_record
              ptr_records = pdns_client.record_from_hostname(ptr_address, 'PTR')
              ptr.records.each do |record|
                if hostname_regex.match(record['content'])
                  pdns_client.delete_record(record['id'])
                  event = Optopus::Event.new
                  event.message = "WARNING: #{node.hostname} has IP #{node.facts['ipaddress']}, but the DNS PTR record points to #{ptr["content"]}. Deleting."
                  event.type = 'dns_replace_ptr_record'
                  event.properties['node_id'] = node.id
                  event.save!
                end
              end
            end

          end

          ## determine if ip of node already exists & if hostname matches
          ## - if ip/hostname doesnt match, raise error/warning & email
          if ip_record.nil? && hostname_record.nil?
            #log.info("ip and hostname for #{node.hostname} do not exist in pdns, create A record")
            domain = pdns_client.domain_from_name(node.facts['domain'])
            if !domain.nil?
              pdns_client.create_record(
                :domain_id => "#{domain['id']}",
                :name      => "#{node.hostname}",
                :type      => "A",
                :content   => "#{node.facts['ipaddress']}",
                :ttl       => "600"
              )
              ## create PTR record while we're at it
              update_or_create_ptr(node)

              event = Optopus::Event.new
              event.message = "Creating A record for IP #{node.facts['ipaddress']} pointing to #{node.hostname}."
              event.type = 'dns_create_record'
              event.properties['node_id'] = node.id
              event.save!
            else
              #log.warn("ip and hostname for #{node.hostname} do not exist in pdns, neither does domain in domains table")
              #event = Optopus::Event.new
              #event.message = "The node '#{node.hostname}' does not belong to a domain in PDNS"
              #event.type = 'dns_update_failed'
              #event.properties['node_id'] = node.id
              #event.save!
            end
          elsif ip_record && hostname_record.nil? && !autoupdate_settings['hostname_regex'].nil?

            # If we have a match, we need to make sure we nuke ALL records with this IP (if they match the regex), then replace
            domain     = pdns_client.domain_from_name(node.facts['domain'])
            ip_records = pdns_client.records_from_content(node.facts['ipaddress'])

            ip_records.each do |record|
              if hostname_regex.match(record['name'])
                pdns_client.delete_record(record['id'])
                event = Optopus::Event.new
                event.message = "WARNING: #{node.hostname} has IP #{node.facts['ipaddress']}, but DNS has this assigned to #{record["name"]}. Deleting."
                event.type = 'dns_replace_record'
                event.properties['node_id'] = node.id
                event.save!
              else
                event = Optopus::Event.new
                event.message = "WARNING: #{node.hostname} has IP #{node.facts['ipaddress']}, but DNS has this assigned to #{record["name"]}. Skipping, since this is not a node record."
                event.type = 'dns_replace_record'
                event.properties['node_id'] = node.id
                event.save!
              end
            end
            pdns_client.create_record(
              :domain_id => "#{domain['id']}",
              :name      => "#{node.hostname}",
              :type      => "A",
              :content   => "#{node.facts['ipaddress']}",
              :ttl       => "600"
            )
            update_or_create_ptr(node)
          elsif hostname_record
            if !hostname_record['content'].eql? node.facts['ipaddress']
              old_ip = hostname_record['content']
              new_ip = node.facts['ipaddress']
              pdns_client.update_record(hostname_record['id'],:content => node.facts['ipaddress'])
              update_or_create_ptr(node)
              event = Optopus::Event.new
              event.message = "Updated A record for #{node.hostname} from #{old_ip} to #{new_ip}"
              event.type = 'dns_update'
              event.properties['node_id'] = node.id
              event.save!
            end
          end

          if node.facts.include?("bmc_ip_address")
            oob_ip_record = pdns_client.record_from_content(node.facts['bmc_ip_address'])
            oob_hostname_record = pdns_client.record_from_hostname("oob" + node.hostname)
            domain = pdns_client.domain_from_name(node.facts['domain'])
            if oob_hostname_record.nil? && oob_ip_record.nil? && !domain.nil?
              pdns_client.create_record(
                :domain_id => "#{domain['id']}",
                :name      => "oob#{node.hostname}",
                :type      => "A",
                :content   => "#{node.facts['bmc_ip_address']}",
                :ttl       => "600"
              )
            end
          end
        end

        def update_or_create_ptr(node)
          pdns_client = Optopus::Plugin::PDNS.pdns_client
          reverse = node.facts['ipaddress'].split(".",4).reverse.join('.') + ".in-addr.arpa"
          ptr_record = pdns_client.record_from_content(node.hostname,"PTR")
          if ptr_record.nil?
            ## no ptr found, go ahead and create it.
            ## TODO:
            ## - we should do something like::  select * from domains where name rlike '^(33\.)?(2\.)?(1\.)?10.in-addr.arpa$';
            ## - this method would match more reverse lookup zones in the hopes to find the most specific one
            ## - for now we assume class A reverse address spece
            reverse_domain = node.facts['ipaddress'].split(".",4)[0] + ".in-addr.arpa"
            domain = pdns_client.domain_from_name(reverse_domain)
            pdns_client.create_record(
              :domain_id => "#{domain['id']}",
              :name      => "#{reverse}",
              :type      => "PTR",
              :content   => "#{node.hostname}",
              :ttl       => "600"
            )
          else
            pdns_client.update_record(ptr_record['id'], :name => reverse)
          end
        end
      end

      helpers do
        def pdns_client
          return Optopus::Plugin::PDNS.pdns_client(is_admin? || is_authorized?('dns_admin'))
        end
      end

      def self.pdns_client(admin=false)
        pdns_settings = {
          :mysql_hostname => plugin_settings['mysql']['hostname'],
          :mysql_username => plugin_settings['mysql']['username'],
          :mysql_password => plugin_settings['mysql']['password'],
          :mysql_database => plugin_settings['mysql']['database'],
          :hostname_regex => plugin_settings['autoupdate']['hostname_regex']
        }
        unless admin
          pdns_settings[:restrict_domains] = plugin_settings['mysql']['restrict_domains']
        end
        @pdns_client = ::PDNS::Client.new(pdns_settings)
      end

      def self.autoupdate_settings
        plugin_settings['autoupdate']
      end

      plugin do
        nav_link :display => 'PowerDNS', :route => '/pdns'
        register_role 'dns_admin'
        register_mixin :nodes, Optopus::Plugin::PDNS::DNSRecordUtils
      end

      # TODO: the below causes redirect loop
      #before '/pdns/*', :auth => :user do
      #  # ensure we at least have a user for all pdns routes
      #end

      get '/pdns', :auth => :user do
        @domains = pdns_client.domains
        erb :pdns_index
      end

      get '/pdns/domain/:id', :auth => :user do
        @records = pdns_client.records(params[:id])
        @domain = pdns_client.domain_from_id(params[:id])
        @domain['id'] = params[:id]
        erb :pdns_domain
      end

      put '/pdns/domain', :auth => [:dns_admin, :admin] do
        begin
          validate_param_presence 'name'
          pdns_client.create_domain(params['name'])
          flash[:success] = "Successfully created a domain for #{params['name']}!"
          register_event "{{ references.user.to_link }} created dns domain #{params['name']}", :type => 'dns_domain_create'
        rescue Exception => e
          status 400
          flash[:error] = e.to_s
        end
        redirect back
      end

      delete '/pdns/domain/:id', :auth => [:dns_admin, :admin] do
        begin
          domain = pdns_client.domain_from_id(params[:id])
          pdns_client.delete_domain(params[:id])
          flash[:success] = "Successfully deleted the domain '#{domain['name']}'!"
          register_event "{{ references.user.to_link }} deleted dns domain #{domain['name']}", :type => 'dns_domain_delete'
          redirect '/pdns'
        rescue Exception => e
          status 400
          flash[:error] = e.to_s
          redirect back
        end
      end

      post '/pdns/domain/:id', :auth => :user do
        begin
          validate_param_presence 'content', 'name', 'type', 'record-id'
          dns_hostname = pdns_client.update_record(
            params['record-id'],
            :domain_id => params[:id],
            :short_name => params['name'],
            :type => params['type'],
            :content => params['content'],
            :ttl => params['ttl']
          )
          register_event "{{ references.user.to_link }} updated dns #{dns_hostname}", :type => 'dns_update'
        rescue Exception => e
          status 400
          flash[:error] = e.to_s
          logger.debug "Invalid PUT request: #{e}"
        end
        redirect back
      end

      put '/pdns/domain/:id', :auth => :user do
        begin
          validate_param_presence 'content', 'name', 'type', 'ttl'
          name = "#{params['name']}.#{pdns_client.domain_from_id(params[:id])['name']}"
          pdns_client.create_record(
            :domain_id => params[:id],
            :name      => name,
            :type      => params['type'],
            :content   => params['content'],
            :ttl       => params['ttl']
          )
          register_event "{{ references.user.to_link }} created dns record for #{name}", :type => 'dns_created'
        rescue Exception => e
          status 400
          flash[:error] = e.to_s
          logger.debug "Invalid PUT request: #{e}"
        end
        redirect back
      end

      delete '/pdns/record/:id', :auth => :user do
        dns_hostname = pdns_client.delete_record(params[:id])
        register_event "{{ references.user.to_link }} deleted dns record for #{dns_hostname}", :type => 'dns_deleted'
        redirect back
      end

      get '/api/pdns/record/:id' do
        record = pdns_client.record_from_id(params[:id])
        domain = pdns_client.domain_from_id(record['domain_id'])['name']
        record['short_name'] = record['name'].gsub(domain, '').chomp('.')
        body(record.to_json)
      end

      def self.registered(app)
        raise 'Missing PDNS plugin configuration' unless app.settings.respond_to?(:plugins) && app.settings.plugins.include?('pdns')
        ActiveRecord::Base.add_observer Optopus::Plugin::PDNS::NodeObserver.instance
        super(app)
      end
    end
  end
end
