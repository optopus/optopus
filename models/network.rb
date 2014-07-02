module Optopus
  class Network < Optopus::Model
    validates :address, :location, :presence => true
    validates_associated :location
    liquid_methods :to_link

    has_many :addresses
    belongs_to :location

    before_save :assign_addresses
    before_destroy :remove_network_id_from_addresses

    default_scope order(:address)

    serialize :properties, ActiveRecord::Coders::Hstore

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
