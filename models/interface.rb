module Optopus
  class Interface < Optopus::Model
    belongs_to :node
    has_one :address

    validates :name, :node, :presence => true
    validates_associated :node
    validates_uniqueness_of :name, :scope => :node_id

    def connections
      Optopus::InterfaceConnection.where("source_interface_id = ? or target_interface_id = ?", self.id, self.id)
    end
  end
end
