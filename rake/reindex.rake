namespace :tire do
  desc 'reindex all models'
  task :reindex do
    Optopus::Models.list.each do |model|
      if model.respond_to?(:search)
        puts "Re-indexing #{model}"
        model.index.delete
        model.index.import model.all
      end
    end
  end
end
