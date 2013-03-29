module Optopus
  class NodeGroup < Optopus::Model
    validates :name, :presence => true, :uniqueness => true
    has_and_belongs_to_many :nodes, :before_add => :validates_node

    def validates_node(node)
      raise ActiveRecord::Rollback if self.nodes.include?(node)
    end
  end
end
