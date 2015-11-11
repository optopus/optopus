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

        def a_record
          pdns_client.record_from_hostname(self.hostname)
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

          ## force admins to manually create/update dns for anything with a tunnel device
          ## Only do this if there's no record for this hostname already
          if !hostname_record && node.facts['interfaces'] && node.facts['interfaces'].include?("tun")
            #event = Optopus::Event.new
            #event.message = "The node '#{node.hostname}/(#{node.facts['ipaddress']})' has an unsupported interface. Please create this record manually."
            #event.type = 'dns_create_failed'
            #event.properties['node_id'] = node.id
            #event.save!
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

              event = Optopus::Event.new
              event.message = "Creating DNS records for #{node.hostname} pointing to IP #{node.facts['ipaddress']}."
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
          elsif hostname_record
            if !hostname_record['content'].eql? node.facts['ipaddress']
              old_ip = hostname_record['content']
              new_ip = node.facts['ipaddress']
              pdns_client.update_record(hostname_record['id'],:content => node.facts['ipaddress'])
              event = Optopus::Event.new
              event.message = "Updated A record for #{node.hostname} from #{old_ip} to #{new_ip}"
              event.type = 'dns_update'
              event.properties['node_id'] = node.id
              event.save!
            end
          end

          # ----------------------------- OOB -----------------------------
          if node.facts.include?("bmc_ip_address")
            unless node.facts["bmc_ip_address"].nil? || node.facts["bmc_ip_address"] == "0.0.0.0" || node.facts["bmc_ip_address"] == node.facts["ipaddress"]
              oob_ip_record       = pdns_client.record_from_content(node.facts['bmc_ip_address'])
              oob_hostname_record = pdns_client.record_from_hostname("oob#{node.hostname}")
              domain              = pdns_client.domain_from_name(node.facts['domain'])

              if oob_hostname_record.nil? && oob_ip_record.nil? && !domain.nil?
                pdns_client.create_record(
                  :domain_id => "#{domain['id']}",
                  :name      => "oob#{node.hostname}",
                  :type      => "A",
                  :content   => "#{node.facts['bmc_ip_address']}",
                  :ttl       => "600"
                )
                event                       = Optopus::Event.new
                event.message               = "Creating DNS records for oob#{node.hostname} pointing to IP #{node.facts['bmc_ip_address']}."
                event.type                  = 'dns_create_oob_record'
                event.properties['node_id'] = node.id
                event.save!
              elsif oob_ip_record && oob_hostname_record.nil? && !autoupdate_settings['hostname_regex'].nil?
                # If we get a match, nuke all records with this IP if they match the regex, then replace them
                oob_records = pdns_client.records_from_content(node.facts['bmc_ip_address'])

                oob_records.each do |oob_record|
                  if hostname_regex.match(oob_record['name'])
                    pdns_client.delete_record(oob_record['id'])
                    event                       = Optopus::Event.new
                    event.message               = "WARNING: oob#{node.hostname} has IP #{node.facts['bmc_ip_address']}, but DNS has this assigned to #{oob_record["name"]}. Deleting."
                    event.type                  = 'dns_replace_oob_record'
                    event.properties['node_id'] = node.id
                    event.save!
                  else
                    event = Optopus::Event.new
                    event.message               = "WARNING: oob#{node.hostname} has IP #{node.facts['bmc_ip_address']}, but DNS has this assigned to #{oob_record["name"]}. Skipping, since this is not a node record."
                    event.type                  = 'dns_replace_oob_record'
                    event.properties['node_id'] = node.id
                    event.save!
                  end
                end

                # Verify that no record are using this IP now
                oob_records = pdns_client.records_from_content(node.facts['bmc_ip_address'])

                if oob_records.count == 0
                  pdns_client.create_record(
                    :domain_id => "#{domain['id']}",
                    :name      => "oob#{node.hostname}",
                    :type      => "A",
                    :content   => "#{node.facts['bmc_ip_address']}",
                    :ttl       => "600"
                  )

                  event                       = Optopus::Event.new
                  event.message               = "Creating DNS records for oob#{node.hostname} pointing to IP #{node.facts['bmc_ip_address']}."
                  event.type                  = 'dns_create_oob_record'
                  event.properties['node_id'] = node.id
                  event.save!
                end

              elsif oob_hostname_record
                if !oob_hostname_record['content'].eql? node.facts['bmc_ip_address']
                  old_ip = oob_hostname_record['content']
                  pdns_client.update_record(oob_hostname_record['id'],:content => node.facts['bmc_ip_address'])

                  event                       = Optopus::Event.new
                  event.message               = "Updated A record for oob#{node.hostname} from #{old_ip} to #{node.facts['bmc_ip_address']}"
                  event.type                  = 'dns_oob_update'
                  event.properties['node_id'] = node.id
                  event.save!
                end
              end
            end
          end
        end

        def after_destroy(node)
          # Make sure we clean up after ourselves

          hostname_array      = node.hostname.split(".",2)
          pdns_client         = Optopus::Plugin::PDNS.pdns_client
          autoupdate_settings = Optopus::Plugin::PDNS.autoupdate_settings
          hostname_regex      = Regexp.new(autoupdate_settings['hostname_regex'])
          ip_records          = pdns_client.records_from_content(node.facts['ipaddress'])
          ip_records.each do |record|
            if hostname_regex.match(record['name'])
              pdns_client.delete_record(record['id'])
              event = Optopus::Event.new
              event.message = "Deleting DNS records for #{node.hostname} pointing to #{node.facts['ipaddress']}"
              event.type = 'dns_delete_record'
              event.properties['node_id'] = node.id
              event.save!
            end
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
          :mysql_hostname      => plugin_settings['mysql']['hostname'],
          :mysql_username      => plugin_settings['mysql']['username'],
          :mysql_password      => plugin_settings['mysql']['password'],
          :mysql_database      => plugin_settings['mysql']['database'],
          :hostname_regex      => plugin_settings['autoupdate']['hostname_regex'],
          :ns_default_content  => plugin_settings['ns_defaults']['content'],
          :ns_default_ttl      => plugin_settings['ns_defaults']['ttl'],
          :soa_default_content => plugin_settings['soa_defaults']['content'],
          :soa_default_ttl     => plugin_settings['soa_defaults']['ttl']
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
          new_domain = pdns_client.create_domain(params['name'])
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
