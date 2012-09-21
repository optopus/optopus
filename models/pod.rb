module Optopus
  class Pod < Optopus::Model
    validates :name, :location, :presence => true
    validates_uniqueness_of :name, :scope => :location_id
    belongs_to :location
    has_many :nodes
  end
end
