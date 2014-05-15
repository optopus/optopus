class AddIndexes < ActiveRecord::Migration
  def up
    add_index :networks, :location_id, :name => 'location_id_ix'
    add_index :networks, :address, :name => 'address_ix'

    add_index :roles_users, :user_id, :name => 'user_id_ix'
    add_index :roles_users, :role_id, :name => 'role_id_ix'

    add_index :addresses, :network_id, :name => 'network_id_ix'
    add_index :addresses, :node_id, :name => 'node_id_ix'
    add_index :addresses, :interface_id, :name => 'interface_id_ix'
    add_index :addresses, :ip_address, :name => 'ip_address_ix'

    add_index :nodes, :device_id, :name => 'device_id_ix'
    add_index :nodes, :hostname, :name => 'hostname_ix'
    add_index :nodes, :serial_number, :name => 'serial_number_ix'
    add_index :nodes, :primary_mac_address, :name => 'primary_mac_address_ix'
    add_index :nodes, :virtual, :name => 'virtual_ix'
    add_index :nodes, :active, :name => 'active_ix'
    add_index :nodes, :type, :name => 'type_ix'
    add_index :nodes, :pod_id, :name => 'pod_id_ix'

    add_index :pods, :location_id, :name => 'pods_location_id_ix'

    add_index :devices, :location_id, :name => 'devices_location_id_ix'

    add_index :interfaces, :node_id, :name => 'interfaces_node_id_ix'

    add_index :node_comments_nodes, :node_id, :name => 'node_comments_nodes_node_id_ix'
    add_index :node_comments_nodes, :node_comment_id, :name => 'node_comment_id_ix'

    add_index :node_groups_nodes, :node_id, :name => 'node_groups_nodes_node_id_ix'
    add_index :node_groups_nodes, :node_group_id, :name => 'node_group_id_ix'
  end

  def down
    remove_index :networks, :name => 'location_id_ix'
    remove_index :networks, :name => 'address_ix'

    remove_index :roles_users, :name => 'user_id_ix'
    remove_index :roles_users, :name => 'role_id_ix'

    remove_index :addresses, :name => 'network_id_ix'
    remove_index :addresses, :name => 'node_id_ix'
    remove_index :addresses, :name => 'interface_id_ix'
    remove_index :addresses, :name => 'ip_address_ix'

    remove_index :nodes, :name => 'device_id_ix'
    remove_index :nodes, :name => 'hostname_ix'
    remove_index :nodes, :name => 'serial_number_ix'
    remove_index :nodes, :name => 'primary_mac_address_ix'
    remove_index :nodes, :name => 'virtual_ix'
    remove_index :nodes, :name => 'active_ix'
    remove_index :nodes, :name => 'type_ix'
    remove_index :nodes, :name => 'pod_id_ix'

    remove_index :pods, :name => 'pods_location_id_ix'

    remove_index :devices,:name => 'devices_location_id_ix'

    remove_index :interfaces, :name => 'interfaces_node_id_ix'

    remove_index :node_comments_nodes, :name => 'node_comments_nodes_node_id_ix'
    remove_index :node_comments_nodes, :name => 'node_comment_id_ix'

    remove_index :node_groups_nodes, :name => 'node_groups_nodes_node_id_ix'
    remove_index :node_groups_nodes, :name => 'node_group_id_ix'
  end
end
