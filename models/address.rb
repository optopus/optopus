module Optopus
  class Address < Optopus::Model
    include Tire::Model::Search
    include Tire::Model::Callbacks

    validates :ip_address, :presence => true, :uniqueness => true
    belongs_to :network
    belongs_to :interface

    before_save :assign_network
    before_save :validate_address_in_network

    default_scope order(:ip_address)

    serialize :properties, ActiveRecord::Coders::Hstore

    set_search_options :default_operator => 'AND',
                       :fields => [:description, 'properties.*']

    set_search_display_key :link

    mapping do
      indexes :description
      indexes :ip_address, :as => 'ip_address.to_cidr', :index => :not_analyzed
      indexes :link,       :as => 'to_link', :index => :not_analyzed
      indexes :properties, :type => 'object'
    end

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
      # If we're dealing with an 'Anycast' network, display the service associated with the address
      # since there is going to be multiple nodes. If we cannot find a service name, fall back
      # to the standard way of handling display.
      if self.network && self.network.properties['anycast'] && self.properties['service']
        self.properties['service']
      else
        self.interface ? (self.interface.node ? self.interface.node.to_link : description) : description
      end
    end

    def to_link
      if self.network
        "<a href=\"/network/#{self.network.id}/address/#{self.ip_address}\">#{self.ip_address}</a>"
      else
        self.ip_address.to_cidr
      end
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
