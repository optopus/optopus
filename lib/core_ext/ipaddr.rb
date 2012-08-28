class IPAddr
  def to_cidr
    "#{to_s}/#{netmask}"
  end

  def netmask
    @mask_addr.to_s(2).count('1')
  end

  # remove the network and broadcast addresses from to_range
  # and return an array of IPs in string form
  def usable_ips
    usable_ips = to_range.to_a
    usable_ips.delete_at(0)
    usable_ips.delete_at(usable_ips.size-1)
    usable_ips.map { |i| i.to_s }
  end
end
