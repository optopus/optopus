require 'ipaddr'

class IPAddr

  def initialize(addr = '::', family = Socket::AF_UNSPEC)
    if !addr.kind_of?(String)
      case family
      when Socket::AF_INET, Socket::AF_INET6
        set(addr.to_i, family)
        @mask_addr = (family == Socket::AF_INET) ? IN4MASK : IN6MASK
        return
      when Socket::AF_UNSPEC
        raise AddressFamilyError, "address family must be specified"
      else
        raise AddressFamilyError, "unsupported address family: #{family}"
      end
    end
    prefix, prefixlen = addr.split('/')
    if prefix =~ /^\[(.*)\]$/i
      prefix = $1
      family = Socket::AF_INET6
    end
    # This allows us to support the ipv4 short hand used
    # commonly by sysadmins such as 10.1.2/23
    if prefix =~ /^\d+\.\d+\.\d+$/
      prefix += '.0'
    end
    if prefix =~ /^\d+\.\d+$/
      prefix += '.0.0'
    end
    if prefix =~ /^\d+$/
      prefix += '.0.0.0'
    end
    # It seems AI_NUMERICHOST doesn't do the job.
    #Socket.getaddrinfo(left, nil, Socket::AF_INET6, Socket::SOCK_STREAM, nil,
    #                  Socket::AI_NUMERICHOST)
    @addr = @family = nil
    if family == Socket::AF_UNSPEC || family == Socket::AF_INET
      @addr = in_addr(prefix)
      if @addr
        @family = Socket::AF_INET
      end
    end
    if !@addr && (family == Socket::AF_UNSPEC || family == Socket::AF_INET6)
      @addr = in6_addr(prefix)
      @family = Socket::AF_INET6
    end
    if family != Socket::AF_UNSPEC && @family != family
      raise AddressFamilyError, "address family mismatch"
    end
    if prefixlen
      mask!(prefixlen)
    else
      @mask_addr = (@family == Socket::AF_INET) ? IN4MASK : IN6MASK
    end
  end

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
