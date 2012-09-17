namespace :optopus do
  desc 'Gather various useful stats'
  task :gatherstats do
    # gather node count for useful graph of nodes over time
    node_count_event = Optopus::Event.new
    node_count_event.type = 'node_count'
    node_count_event.properties['node_count'] = Optopus::Node.active.count
    node_count_event.message = "logged that we have #{node_count_event.properties['node_count']} active nodes"
    node_count_event.save!
  end
end
