module MCollective
  module Agent
    class Registration
      def handlemsg(msg, connection)
        req = msg[:body]
        if req.nil?
          Log.instance.info("Invalid request received!")
          return nil
        end

        if req['facts'].nil?
          Log.instance.info("Invalid request received, no facts.")
          return nil
        end

        if req['facts']['fqdn'].nil?
          Log.instance.info("Got request with no fqdn!")
          return nil
        end

        begin
          Timeout::timeout(3) {
            facts = req['facts']
            uri = URI.parse('http://optopus/api/node/register')
            http = Net::HTTP.new(uri.host, uri.port)
            request = Net::HTTP::Post.new(uri.path)
            optopus_data = {
              :hostname            => facts['fqdn'],
              :serial_number       => facts['serialnumber'],
              :primary_mac_address => facts['macaddress'],
              :virtual             => facts['is_virtual'],
              :facts               => facts,
            }
            optopus_data[:libvirt] = req['libvirt'] if req.include?('libvirt')
            Log.instance.debug("posting to optopus: #{optopus_data.inspect}")
            request.body = optopus_data.to_json
            request['Content-Type'] = 'application/json'
            response = http.request(request)
            Log.instance.debug("response from optopus: #{response}")
          }
        rescue Timeout::Error
          Log.instance.error("Timeout talking to optopus")
        rescue Exception => e
          Log.instance.error("Unexpected error talking to optopus: #{e}")
        end

        # if you're not using queues for registration, you will want to comment out the nil
        nil
      end
    end
  end
end
