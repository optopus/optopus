module MCollective
  module Registration
    class Meta<Base
      def body
        begin
          result = {
            :agentlist => [],
            :facts     => {},
            :classes   => [],
          }

          cfile = Config.instances.classesfile
          if File.exists?(cfile)
            result[:classes] = File.readlines(cfile).map {|i| i.chomp }
          end

          result[:agentlist] = Agents.agentlist
          result[:facts] = PluginManager['facts_plugin'].get_facts

          # if we have the libvirtd agent, use the list method
          # to gather metadata about the hypervisor
          if PluginManager.include?('libvirtd_agent')
            result[:libvirt] = PluginManager['libvirtd_agent'].list
          end

          # use a queue instead of a topic to send mcollective registration data
          PluginManager['connector_plugin'].connection.publish('/queue/mcollective.registration', result.to_json)
        rescue Exception => e
          Log.error("Unexpected error: #{e}")
          Log.error(e.backtrace.join("\n\t"))
        end
        nil
      end
    end
  end
end
