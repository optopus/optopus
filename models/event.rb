module Optopus
  class Event < Optopus::Model
    include Tire::Model::Search
    include Tire::Model::Callbacks
    include AttributesToLiquidMethodsMapper
    serialize :properties, ActiveRecord::Coders::Hstore

    set_search_options :default_operator => 'AND', :fields => [:event_message, :event_type]
    set_highlight_fields :event_message, :event_type
    set_search_display_key :event_message

    mapping do
      indexes :id, :index => :not_analyzed
      indexes :event_message, :as => "rendered_message", :boost => 10
      indexes :event_type, :as => 'type', :boost => 20
    end

    def rendered_message
      Liquid::Template.parse(message).render 'references' => references
    end

    def type
      properties['event_type']
    end

    def type=(value)
      properties['event_type'] = value
    end

    # TODO: split references out into their own hstore column to avoid collision
    def references
      references = Hash.new
      properties.each do |key, value|
        next if key == 'event_type'
        if key.match(/^(.*)_(username|id|hostname)/)
          reference_type = $1
          column = $2.to_sym
          Optopus::Models.list.each do |model|
            if model.respond_to?(:table_name) && model.table_name.singularize == reference_type
              references[reference_type] = model.where(column => value).first
              break
            end
          end
        end
      end
      references
    end

    def self.unique_event_types
      select("DISTINCT properties -> 'event_type' AS event_type").inject([]) {|a,e| a << e.read_attribute(:event_type)}
    end

    def self.group_event_type_by_created_at(event_type)
      where("properties -> 'event_type' = '#{event_type}'").order('date_created_at ASC').count(:group => "DATE(created_at)")
    end
  end
end
