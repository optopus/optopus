module MCollective
  module Agent
    class Libvirtd<RPC::Agent
      def list
        begin
          libvirt = ::Libvirt::open
          raise 'Unable to connect to libvirtd' if libvirt.closed?
          data = {
            :active_domains     => libvirt.list_domains,          # returns IDs
            :inactive_domains   => libvirt.list_defined_domains,  # returns by name
            :node_total_memory  => libvirt.node_get_info.memory,  # in kb
            :node_free_memory   => libvirt.node_free_memory,      # in bytes
            :node_total_cpus    => libvirt.node_get_info.cpus,
            :node_running_cpus  => 0,
            :domains            => Array.new
          }

          # this should really be changed to use an xml library
          vnc_port_match = /graphics type='vnc' port='(\d+)'/

          # first lets gather data about all active domains
          data[:active_domains].each do |id|
            vnc_port = nil
            domain = libvirt.lookup_domain_by_id(id)
            info = domain.info

            if domain.xml_desc.match(vnc_port_match)
              vnc_port = $1
            end

            data[:domains] << {
              :id         => id,
              :name       => domain.name,
              :autostart  => domain.autostart,
              :memory     => info.memory,
              :state      => info.state,
              :cpu_count  => info.nr_virt_cpu,
              :vnc_port   => vnc_port
            }
            data[:node_running_cpus] += info.nr_virt_cpu
            domain.free
          end

          # inactive domain data is gathered slightly differently
          data[:inactive_domains].each do |name|
            domain = libvirt.lookup_domain_by_name(name)
            info = domain.info
            data[:domains] << {
              :id         => '-1',
              :name       => domain.name,
              :autostart  => domain.autostart,
              :memory     => info.memory,
              :state      => info.state,
              :cpu_count  => info.nr_virt_cpu
            }
            domain.free
          end
        rescue Exception => e
          Log.instance.error("Failed to gather data: #{e.to_s}")
          Log.instance.error(e.backtrace.join("\n\t"))
        ensure
          if libvirt && !libvirt.closed?
            libvirt.close
          end
        end
      end
    end
  end
end
