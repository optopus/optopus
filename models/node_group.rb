module Optopus
  class NodeGroup < Optopus::Model
    validates :name, :presence => true
    has_and_belongs_to_many :nodes
  end
end
