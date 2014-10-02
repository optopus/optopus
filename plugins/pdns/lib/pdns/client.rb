require 'mysql2'
module PDNS
  class DuplicateDomain < Exception ; end

  class Client
    def initialize(options={})
      @mysql_hostname = options.delete(:mysql_hostname)
      @mysql_username = options.delete(:mysql_username)
      @mysql_password = options.delete(:mysql_password)
      @mysql_database = options.delete(:mysql_database)
      @restrict_domains = options.delete(:restrict_domains)
      raise 'Missing mysql hostname' if @mysql_hostname.nil?
      raise 'Missing mysql username' if @mysql_username.nil?
      raise 'Missing mysql password' if @mysql_password.nil?
      raise 'Missing mysql database' if @mysql_database.nil?
    end

    def domains
      domains = Array.new
      if @restrict_domains.nil?
        domains += mysql_query("SELECT id, name FROM domains ORDER BY name").to_a
      else
        @restrict_domains.each do |restriction|
          domains += mysql_query("SELECT id, name FROM domains WHERE name LIKE '#{escape(restriction)}'").to_a
        end
      end
      domains
    end

    def domain_from_id(id)
      mysql_query("SELECT name from domains WHERE id=#{escape(id.to_s)}").first
    end

    def domain_from_name(name)
      mysql_query("SELECT * from domains WHERE name='#{escape(name.to_s)}'").first
    end

    def record_from_id(id)
      mysql_query("SELECT * FROM records WHERE id=#{escape(id.to_s)}").first
    end

    def record_from_hostname(hostname,type="A") 
      mysql_query("SELECT * FROM records WHERE name='#{escape(hostname.to_s)}' and type='#{type}'").first
    end

    def record_from_content(ipaddress,type="A") 
      mysql_query("SELECT * FROM records WHERE content='#{escape(ipaddress.to_s)}' and type='#{type}'").first
    end

    def records_from_content(ipaddress,type="A")
      mysql_query("SELECT * FROM records WHERE content='#{escape(ipaddress.to_s)}' and type='#{type}'")
    end

    def update_record(id, data={})
      # TODO: clean this up..
      record = record_from_id(id)
      record.delete('id')
      if data.include?(:short_name)
        domain = domain_from_id(data[:domain_id])
        raise 'Invalid domain_id' if domain.nil?
        record['name'] = data[:short_name] + '.' + domain['name']
      end
      update_string = ''
      record.keys.each do |key|
        record[key] = data.delete(key.to_sym) if data.include?(key.to_sym)
        update_string += "#{key}='#{escape(record[key].to_s)}', " unless record[key].nil?
      end
      mysql_query("UPDATE records SET #{update_string.chomp(', ')} WHERE id=#{id}")
      record['name']
    end

    def delete_record(id)
      name = record_from_id(id)['name']
      mysql_query("DELETE FROM records WHERE id=#{escape(id.to_s)}")
      name
    end

    def records(id=nil)
      if id.nil?
        query = "SELECT * FROM records ORDER BY name"
      else
        query = "SELECT * FROM records WHERE domain_id=#{escape(id)} ORDER BY name"
      end
      mysql_query(query)
    end

    def create_domain(name)
      if domains.any? { |d| d['name'] == name }
        raise DuplicateDomain, 'domain name taken!'
      end
      mysql_query("INSERT INTO domains SET name='#{escape(name)}', type='NATIVE'")
      domain = domain_from_name(name)
      mysql_query("INSERT INTO zones SET domain_id=#{domain['id']}, owner=1, zone_templ_id=1")
      domain
    end

    def delete_domain(id)
      name = domain_from_id(id)['name']
      mysql_query("DELETE FROM domains WHERE id=#{escape(id.to_s)}")
      mysql_query("DELETE FROM zones WHERE domain_id=#{escape(id.to_s)}")
      name
    end

    def create_record(options={})
      domain_id = options.delete(:domain_id)
      name = options.delete(:name)
      type = options.delete(:type)
      content = options.delete(:content)
      ttl = options.delete(:ttl)
      raise 'Missing domain_id' if domain_id.nil?
      raise 'Missing name' if name.nil?
      raise 'Missing type' if type.nil?
      raise 'Missing content' if content.nil?
      raise 'Missing ttl' if ttl.nil?
      mysql_query("INSERT INTO records SET domain_id=#{escape(domain_id)}, name='#{escape(name)}', type='#{escape(type)}', content='#{escape(content)}', ttl=#{escape(ttl)}")
    end

    private

    def mysql_query(string)
      results = nil
      mysql { |c| results = c.query(string) }
      results
    end

    def mysql(&block)
      connection_options = { :host => @mysql_hostname, :username => @mysql_username, :password => @mysql_password, :database => @mysql_database }
      client = Mysql2::Client.new(connection_options)
      yield client
      client.close
    end

    def escape(string)
      Mysql2::Client.escape(string)
    end
  end
end
