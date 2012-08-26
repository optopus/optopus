module Optopus
  class App
    helpers do
      def hypervisor_planner_settings
        return @hypervisor_planner_settings if @hypervisor_planner_settings
        defaults = {
          :max_cpus          => 15,
          :cpu_multiplier    => 1,
          :memory_multiplier => 4,
          :disk_multiplier   => 36,
        }
        @hypervisor_planner_settings = settings.respond_to?(:hypervisor_planner) ? defaults.merge(settings.hypervisor_planner.symbolize_keys) : defaults
      end
    end

    get '/util/hypervisor_planner' do
      begin
        validate_param_presence 'node-cpus', 'node-memory', 'node-disk'
        raise 'node-cpus must be an integer greater than 0!' unless params['node-cpus'].to_i > 0
        raise 'node-memory must be an integer greater than 0!' unless params['node-memory'].to_i > 0
        raise 'node-disk must be an integer greater than 0!' unless params['node-disk'].to_i > 0

        # our web interface passes in memory and disk a gigabytes
        # the data stored, is in bytes so we convert first
        memory = params['node-memory'].to_i * 1024**3
        disk = params['node-disk'].to_i * 1024**3

        location = nil
        if params['node-location'] && params['node-location'] != 'Any'
          location = params['node-location']
        end

        # create a hash of the appropriate elasticsearch fields
        # where our libvirt data is stored
        ranges = {
          'libvirt.free_disk' => { :gt => disk },
          'libvirt.node_free_cpus' => { :gt => params['node-cpus'].to_i },
          'libvirt.node_free_memory' => { :gt => memory },
        }

        @capable_hypervisors = Optopus::Hypervisor.capacity_search(ranges, location).sort { |a,b| a.hostname <=> b.hostname }
        @capacity_search_string = "#{params['node-memory']} GB of memory, #{params['node-disk']} GB of disk, #{params['node-cpus']} and CPU cores in #{location ? location : 'any location'}"
      rescue Exception => e
        flash[:error] = e.to_s
      end
      erb :hypervisor_planner_results
    end

    get '/util/hypervisor_planner/form' do
      erb :hypervisor_planner_form
    end
  end
end
