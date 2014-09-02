module Optopus
  class Network < Optopus::Model
    include Tire::Model::Search
    include Tire::Model::Callbacks

    validates :address, :location, :presence => true
    validates_associated :location
    liquid_methods :to_link

    has_many :addresses
    belongs_to :location

    before_save :assign_addresses
    before_destroy :remove_network_id_from_addresses

    default_scope order(:address)

    serialize :properties, ActiveRecord::Coders::Hstore

    set_search_options :default_operator => 'AND',
                       :fields => [:description, :location, 'properties.*']

    set_search_display_key :link

    mapping do
      indexes :address,    :as => 'address.to_cidr', :index => :not_analyzed
      indexes :created_at
      indexes :description
      indexes :link,       :as => 'to_link', :index => :not_analyzed
      indexes :location,   :as => 'location_name', :boot => 10
      indexes :properties, :type => 'object'
      indexes :updated_at
      indexes :vlan_id
    end

    # A wrapper method for indexing the location name of a node
    def location_name
      location ? location.common_name : nil
    end

    def to_link
      "<a href=\"/network/#{self.id}\">#{self.address.to_cidr}</a>"
    end

    def available_ips
      address.usable_ips - used_ips
    end

    def used_ips
      addresses.map { |a| a.ip_address.to_s }
    end

    # Return the usage percentage of this network
    def usage
      if address.netmask < 16
        return 'n/a'
      end
      possible_ips = available_ips.size + used_ips.size
      sprintf "%.2f", (used_ips.size.to_f / possible_ips.to_f) * 100
    end

    def self.possible_networks(ip)
      where('address >> ?', ip)
    end

    private

    # Associate addresses that are contained in this network, but
    # only if they do not have a network assigned already
    def assign_addresses
      Optopus::Address.where(:network_id => nil).where('ip_address << ?', self.address.to_cidr).each do |address|
        self.addresses << address
      end

      # if we changed our cidr address, go through and update
      # addresses that are no longer part of this network
      if !self.new_record? && self.address_changed?
        self.addresses.where('NOT ip_address << ?', self.address.to_cidr).update_all('network_id = NULL')
      end
    end

    # Make sure that we unset network_id for all addresses associated
    # with this network before we destroy it
    def remove_network_id_from_addresses
      self.addresses.update_all('network_id = NULL')
    end
  end
end
