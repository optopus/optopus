require 'random-word'
def random_mac_address
  ("%02x" % ((rand*64).to_i * 4 | 2)) + (0..4).inject('') { |s,x| s+":%02x" %(rand * 256).to_i }
end

def random_hostname
  "#{RandomWord.nouns.next}#{rand(100)}.optopus.local"
end

def random_serial_number
  (0..9).inject('') { |s,x| s + rand(9).to_s }
end

# Generate a bunch of seed data for use in development
unless Optopus::App.production?
  location_data = [
    {
      :common_name => 'ma01',
      :city => 'Boston',
      :state => 'MA',
    },
    {
      :common_name => 'tx01',
      :city => 'Dallas',
      :state => 'TX',
    },
    {
      :common_name => 'nyc01',
      :city => 'New York',
      :state => 'NY',
    }
  ]

  location_data.each do |data|
    if Optopus::Location.where(:common_name => data[:common_name]).first.nil?
      Optopus::Location.create!(:common_name => data[:common_name], :city => data[:city], :state => data[:state])
    end
  end

  valid_location_names = Optopus::Location.all.inject([]) { |a, n| a << n.common_name }
  nodes_to_generate = ENV['NODES'] || 1000
  (1..nodes_to_generate.to_i).each do
    n = Optopus::Node.new
    n.hostname = random_hostname
    n.primary_mac_address = random_mac_address
    n.serial_number = random_serial_number
    n.virtual = false
    n.facts = {
      'location' => valid_location_names[rand(valid_location_names.size)],
      'serialnumber' => n.serial_number,
      'macaddress' => n.primary_mac_address,
    }
    n.save!
  end
end
