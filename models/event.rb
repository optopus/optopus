module Optopus
  class Event < ActiveRecord::Base
    include AttributesToLiquidMethodsMapper
    serialize :properties, ActiveRecord::Coders::Hstore
    belongs_to :event_type
    validates_associated :event_type

    def rendered_message
      Liquid::Template.parse(message).render 'references' => references
    end

    def references
      references = Hash.new
      properties.each do |key, value|
        if key.match(/^(.*)_id/)
          reference_type = $1
          puts "#{$1} => #{value}"
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
