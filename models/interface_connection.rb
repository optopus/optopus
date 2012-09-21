module Optopus
  class InterfaceConnection < Optopus::Model
    belongs_to :source_interface, :class_name => 'Optopus::Interface'
    belongs_to :target_interface, :class_name => 'Optopus::Interface'

    validates :source_interface_id, :target_interface_id, :presence => true
    validates_uniqueness_of :target_interface_id, :scope => :source_interface_id
    validates_uniqueness_of :source_interface_id, :scope => :target_interface_id

    after_create :ensure_reverse_connection_exists
    after_destroy :ensure_reverse_connection_is_removed

    # Helper to return the reverse interface connection
    def reverse_interface_connection
      InterfaceConnection.where(reverse_interfaces).first
    end

    private

    # Helper to return a hash where the source/target ids are reversed
    def reverse_interfaces
      {
        :source_interface_id => self.target_interface_id,
        :target_interface_id => self.source_interface_id,
      }
    end

    # Every interface connection has two rows since we are using source_interface_id as a
    # foreign key on the interfaces table. We must make sure that when a new connection is
    # created, that we also create a connection where the source/target interfaces are reversed
    def ensure_reverse_connection_exists
      if reverse_interface_connection.nil?
        InterfaceConnection.create!(reverse_interfaces)
      end
    end

    # See above, but this time remove the reverse interface connection
    def ensure_reverse_connection_is_removed
      if reverse_interface_connection
        reverse_interface_connection.destroy
      end
    end
  end
end
