module Optopus
  class NodeComment < Optopus::Model
    has_and_belongs_to_many :node
    #has_many :nodes
    validates_presence_of :comment

  end
end
