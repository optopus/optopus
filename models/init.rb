require_relative 'device'
require_relative 'node'
require_relative 'location'
require_relative 'user'
require_relative 'role'
require_relative 'event'
require_relative 'address'
require_relative 'network'

# ensure any data registered by plugins exists
Optopus::Models.list.each do |model|
  if register_data = Optopus::Models.model_data[model.to_s]
    register_data.each do |values|
      obj = model.where(values).first || model.new(values)
      obj.save!
    end
  end
end
