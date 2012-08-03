namespace :optopus do
  desc 'Cleanup nodes that have not checked in for dead_node_threshold days'
  task :deadnodes do
    dead_node_threshold = Optopus::App.settings.respond_to?('dead_node_threshold') ? Optopus::App.settings.dead_node_threshold.to_i : 1
    puts "Dead threshold: #{dead_node_threshold} days"
    Optopus::Node.where(:active => true).where("updated_at < ?", dead_node_threshold.day.ago).each do |node|
      node.active = false
      node.save!
    end
  end
end
