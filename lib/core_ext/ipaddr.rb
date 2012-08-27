class IPAddr
  def to_cidr
    "#{to_s}/#{netmask}"
  end

  def netmask
    @mask_addr.to_s(2).count('1')
  end
end
