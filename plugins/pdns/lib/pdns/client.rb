require 'mysql2'
module PDNS
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

      @mysql_client = Mysql2::Client.new(:host => @mysql_hostname, :username => @mysql_username, :password => @mysql_password, :database => @mysql_database)
    end

    def domains
      domains = Array.new
      if @restrict_domains.nil?
        @mysql_client.query("SELECT id, name FROM domains ORDER BY name").each do |row|
          domains << row
        end
      else
        @restrict_domains.each do |restriction|
          @mysql_client.query("SELECT id, name FROM domains WHERE name LIKE '#{escape(restriction)}'").each do |row|
            domains << row
          end
        end
      end
      domains
    end

    def domain_from_id(id)
      @mysql_client.query("SELECT name FROM domains WHERE id=#{escape(id.to_s)}").first
    end

    def record_from_id(id)
      @mysql_client.query("SELECT * FROM records WHERE id=#{escape(id.to_s)}").first
    end

    def update_record(id, data={})
      # TODO: clean this up..
      record = record_from_id(id)
      record.delete('id')
      domain = domain_from_id(data[:domain_id])
      raise 'Invalid domain_id' if domain.nil?
      if data.include?(:short_name)
        record['name'] = data[:short_name] + '.' + domain['name']
      end
      update_string = ''
      record.keys.each do |key|
        record[key] = data.delete(key.to_sym) if data.include?(key.to_sym)
        update_string += "#{key}='#{escape(record[key].to_s)}', " unless record[key].nil?
      end
      @mysql_client.query("UPDATE records SET #{update_string.chomp(', ')} WHERE id=#{id}")
      record['name']
    end

    def delete_record(id)
      name = record_from_id(id)['name']
      @mysql_client.query("DELETE FROM records WHERE id=#{escape(id.to_s)}")
      name
    end

    def records(id=nil)
      if id.nil?
        @mysql_client.query("SELECT * FROM records ORDER BY name").to_a
      else
        @mysql_client.query("SELECT * FROM records WHERE domain_id=#{escape(id)} ORDER BY name").to_a
      end
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
      @mysql_client.query("INSERT INTO records SET domain_id=#{escape(domain_id)}, name='#{escape(name)}', type='#{escape(type)}', content='#{escape(content)}', ttl=#{escape(ttl)}")
    end

    private

    def escape(string)
      @mysql_client.escape(string)
    end
  end
end
