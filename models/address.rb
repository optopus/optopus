module Optopus
  class Address < Optopus::Model
    validates :ip_address, :presence => true
    belongs_to :network
    belongs_to :interface

    before_save :assign_network
    before_save :validate_address_in_network

    # Return addresses that do not have any network associations
    def self.lonely
      where(:network_id => nil)
    end

    # Return networks that this address could belong to
    def possible_networks
      @possible_networks ||= Optopus::Network.where('address >> ?', self.ip_address.to_cidr)
    end

    # Display either an associated node's hostname or
    # the IP's description
    def display
      node ? node.hostname : description
    end

    private

    # Don't allow an address to be associated with a network
    # if the network does not contain the address
    def validate_address_in_network
      if self.network
        if possible_networks.find_by_id(self.network.id).nil?
          errors.add(:network)
          raise ActiveRecord::RecordInvalid.new(self), "#{self.ip_address.to_s} is not part of #{self.network.address.to_cidr}"
        end
      end
    end

    # Attempt to associate a network to this address
    # only if one is not already associated
    def assign_network
      if self.network.nil?
        # Only assign a network if we found exactly one
        if possible_networks.size == 1
          self.network = possible_networks.first
        end
      end
    end
  end
end
