unless Optopus::App.production?
  # create a bunch of seed data for development purposes
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
  device_data = [
    {
      :serial_number => 'test001',
      :primary_mac_address => '01:02:03:04:05:06',
      :location_name => 'tx01'
    },
    {
      :serial_number => 'test002',
      :primary_mac_address => '01:02:03:04:05:05',
      :location_name => 'ma01'
    },
    {
      :serial_number => 'test003',
      :primary_mac_address => '01:02:03:04:05:09',
      :location_name => 'nyc01'
    },
    {
      :serial_number => 'test004',
      :primary_mac_address => '01:02:03:04:05:08',
      :location_name => 'ma01'
    },
    {
      :serial_number => 'test005',
      :primary_mac_address => '01:02:03:04:05:07',
      :location_name => 'ma01'
    },
  ]
  device_data.each do |data|
    location = Optopus::Location.where(:common_name => data[:location_name]).first
    device = Optopus::Device.new(:serial_number => data[:serial_number], :primary_mac_address => data[:primary_mac_address])
    device.location = location
    device.save!
    node = Optopus::Node.new(:serial_number => data[:serial_number], :primary_mac_address => data[:primary_mac_address])
    node.virtual = false
    node.hostname = data[:serial_number]
    node.save!
  end
end
