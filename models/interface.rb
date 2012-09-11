module Optopus
  class Interface < Optopus::Model
    belongs_to :node
    has_one :address

    validates :name, :node, :presence => true
    validates_associated :node
    validates_uniqueness_of :name, :scope => :node_id
  end
end
