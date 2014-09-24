namespace :tire do
  desc 'reindex all models, or models listed in OPTOPUS_MODEL_TYPES'
  task :reindex do
    types = ENV['OPTOPUS_MODEL_TYPES']
    models = nil
    if types.nil?
      models = Optopus::Models.list
    else
      models = types.split(',').map { |t| Optopus::Models.type(t.strip) }.uniq
    end
    models.each do |model|
      if model.respond_to?(:search)
        puts "Re-indexing #{model}"
        model.index.delete
        model.index.import model.all
      end
    end
  end
end
