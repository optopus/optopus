require 'optopus/plugin'
require_relative 'lib/pdns/client'
module Optopus
  module Plugin
    module PDNS
      extend Optopus::Plugin

      helpers do
        def pdns_client
          return @pdns_client if @pdns_client
          pdns_settings = {
            :mysql_hostname => settings.plugins['pdns']['mysql']['hostname'],
            :mysql_username => settings.plugins['pdns']['mysql']['username'],
            :mysql_password => settings.plugins['pdns']['mysql']['password'],
            :mysql_database => settings.plugins['pdns']['mysql']['database'],
          }
          unless is_admin?
            pdns_settings[:restirct_domains] = settings.plugins['pdns']['mysql']['restrict_domains']
          end
          @pdns_client = ::PDNS::Client.new(pdns_settings)
        end
      end

      plugin do
        nav_link :display => 'PowerDNS', :route => '/pdns'
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
        super(app)
      end
    end
  end
end
