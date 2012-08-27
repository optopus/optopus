module Optopus
  class Network < Optopus::Model
    validates :address, :presence => true
    has_many :addresses

    before_save :assign_addresses

    private

    # Associate addresses that are contained in this network, but
    # only if they do not have a network assigned already
    def assign_addresses
      Optopus::Address.where(:network_id => nil).where('ip_address << ?', self.address.to_cidr).each do |address|
        self.addresses << address
      end
    end
  end
end
