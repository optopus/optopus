module Optopus
  class Network < Optopus::Model
    validates :address, :presence => true
    has_many :addresses
  end
end
