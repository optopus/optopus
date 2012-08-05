module Optopus
  class Event < ActiveRecord::Base
    include AttributesToLiquidMethodsMapper
    serialize :properties, ActiveRecord::Coders::Hstore

    def rendered_message
      Liquid::Template.parse(message).render 'references' => references
    end

    def type
      properties['event_type']
    end

    def type=(value)
      properties['event_type'] = value
    end

    def references
      references = Hash.new
      properties.each do |key, value|
        if key.match(/^(.*)_id/)
          reference_type = $1
          Optopus.models.each do |model|
            if model.respond_to?(:table_name) && model.table_name.singularize == reference_type
              references[reference_type] = model.find_by_id(value)
              break
            end
          end
        end
      end
      references
    end
  end
end
