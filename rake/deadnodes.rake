namespace :optopus do
  desc 'Cleanup nodes that have not checked in for dead_node_threshold days'
  task :deadnodes do
    dead_node_threshold = Optopus::App.settings.respond_to?('dead_node_threshold') ? Optopus::App.settings.dead_node_threshold.to_i : 1
    puts "Dead threshold: #{dead_node_threshold} days"
    nodes = Optopus::Node.where(:active => true).where("updated_at < ?", dead_node_threshold.day.ago)
    nodes.each do |node|
      node.active = false
      node.save!
    end

    # log that we marked a bunch of nodes dead
    if nodes.size > 0
      event = Optopus::Event.new
      event.message = "marked #{nodes.size} nodes as dead"
      event.type = 'inactive_node_count'
      event.properties['inactive_node_count'] = nodes.size
      event.save!
    end
  end
end
