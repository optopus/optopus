module Optopus
  class Interface < Optopus::Model
    belongs_to :node
    has_one :address
    has_many :connections, :class_name => 'Optopus::InterfaceConnection', :foreign_key => :source_interface_id

    validates :name, :node, :presence => true
    validates_associated :node
    validates_uniqueness_of :name, :scope => :node_id

    before_destroy :destroy_interface_connections, :destroy_address

    private

    def destroy_interface_connections
      self.connections.destroy_all
    end

    def destroy_address
      self.address.destroy if self.address
    end
  end
end
