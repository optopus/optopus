module Optopus
  class InterfaceConnection < Optopus::Model
    belongs_to :source_interface, :class_name => 'Optopus::Interface'
    belongs_to :target_interface, :class_name => 'Optopus::Interface'

    validates :source_interface_id, :target_interface_id, :presence => true
    validates_uniqueness_of :target_interface_id, :scope => :source_interface_id
    validates_uniqueness_of :source_interface_id, :scope => :target_interface_id
  end
end
