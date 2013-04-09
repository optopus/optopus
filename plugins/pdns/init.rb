require 'optopus/plugin'
require_relative 'lib/pdns/client'
module Optopus
  module Plugin
    module PDNS
      extend Optopus::Plugin

      class NodeObserver < ActiveRecord::Observer
        observe Optopus::Node

        def after_save(node)
          hostname_array = node.hostname.split(".",2)
          pdns_client = Optopus::Plugin::PDNS.pdns_client

          ip_record = pdns_client.record_from_content(node.facts['ipaddress'])
          hostname_record = pdns_client.record_from_hostname(node.hostname)

          ## force admins to manually create/update dns for anything with a tunnel device
          if node.facts['interfaces'] && node.facts['interfaces'].include?("tun")
            return
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
            else
              #log.warn("ip and hostname for #{node.hostname} do not exist in pdns, neither does domain in domains table")
              event = Optopus::Event.new
              event.message = "The node '#{node.hostname}' does not belong to a domain in PDNS"
              event.type = 'dns_update_failed'
              event.properties['node_id'] = node.id
              event.save!
            end
          elsif ip_record && hostname_record.nil?
            #log.warn("ip exists in records table, hostname '#{node.hostname}' do not exist, emailing error")
            event = Optopus::Event.new
            event.message = "The node '#{node.hostname}' has an ip of '#{node.facts['ipaddress']}, which already exists in the records table. dns update failed"
            event.type = 'dns_update_failed'
            event.properties['node_id'] = node.id
            event.save!
          elsif hostname_record
            if !hostname_record['content'].eql? node.facts['ipaddress']
              old_ip = hostname_record['content']
              new_ip = node.facts['ipaddress']
              pdns_client.update_record(hostname_record['id'],:content => node.facts['ipaddress'])
              update_or_create_ptr(node)
              event = Optopus::Event.new
              event.message = "Automatic DNS update: updated A record dns of #{node.hostname} from #{old_ip} to #{new_ip}" 
              event.type = 'dns_update'
              event.properties['node_id'] = node.id
              event.save!
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
        }
        unless admin
          pdns_settings[:restrict_domains] = plugin_settings['mysql']['restrict_domains']
        end
        @pdns_client = ::PDNS::Client.new(pdns_settings)
      end

      plugin do
        nav_link :display => 'PowerDNS', :route => '/pdns'
        register_role 'dns_admin'
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
        @domain = pdns_client.domain_from_id(params[:id])['name']
        erb :pdns_domain
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
