unless Optopus::App.production?
  # create a bunch of seed data for development purposes
  [ 'ma01', 'nyc01', 'tx01' ].each do |location_name|
    if Optopus::Location.where(:common_name => location_name).first.nil?
      Optopus::Location.create!(:common_name => location_name)
    end
  end
  appliance_data = [
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
  appliance_data.each do |data|
    location = Optopus::Location.where(:common_name => data[:location_name]).first
    appliance = Optopus::Appliance.new(:serial_number => data[:serial_number], :primary_mac_address => data[:primary_mac_address])
    appliance.location = location
    appliance.save!
    node = Optopus::Node.new(:serial_number => data[:serial_number], :primary_mac_address => data[:primary_mac_address])
    node.virtual = false
    node.hostname = data[:serial_number]
    node.save!
  end
end
