module Optopus
  class Interface < Optopus::Model
    belongs_to :node
    has_one :address
    has_many :connections, :class_name => 'Optopus::InterfaceConnection', :foreign_key => :source_interface_id

    validates :name, :node, :presence => true
    validates_associated :node
    validates_uniqueness_of :name, :scope => :node_id

    before_destroy :remove_interface_connections

    private

    def remove_interface_connections
      self.connections.each do |connection|
        connection.destroy
      end
    end
  end
end
