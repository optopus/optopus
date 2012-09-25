module Optopus
  class Pod < Optopus::Model
    validates :name, :location, :presence => true
    validates_uniqueness_of :name, :scope => :location_id
    belongs_to :location
    has_many :nodes

    def hypervisors
      nodes.where(:type => Optopus::Hypervisor)
    end

    def hypervisor_resources
      return @hypervisor_resources if @hypervisor_resources
      resources = {
        :node_free_memory  => 0,
        :node_total_memory => 0,
        :node_total_cpus   => 0,
        :node_running_cpus => 0,
        :free_disk         => 0,
        :used_disk         => 0,
      }
      resources = hypervisors.where("properties ? 'libvirt_data'").inject(resources) do |resources, hypervisor|
        resources.keys.inject(resources) do |resources, key|
          resources[key] += hypervisor.libvirt_data[key.to_s] unless hypervisor.libvirt_data[key.to_s].nil?
          resources
        end
      end
      resources[:node_total_memory] *= 1024
      @hypervisor_resources = resources
    end

    def hypervisor_utilization
      return @hypervisor_utilization if @hypervisor_utilization
      r = hypervisor_resources
      @hypervisor_utilization = {
        :memory => sprintf("%0.2f", ((r[:node_total_memory] - r[:node_free_memory]).to_f / r[:node_total_memory].to_f) * 100),
        :cpu    => sprintf("%0.2f", (r[:node_running_cpus].to_f / r[:node_total_cpus].to_f) * 100),
        :disk   => sprintf("%0.2f", r[:used_disk].to_f / (r[:used_disk] + r[:free_disk]) * 100),
      }
    end

    def network_nodes
      nodes.where(:type => Optopus::NetworkNode)
    end

    def regular_nodes
      nodes.where("type != ? or type IS NULL", 'Optopus::NetworkNode')
    end

    def to_link
      "<a href=\"/pods/#{self.id}\">#{self.name}</a>"
    end

  end
end
