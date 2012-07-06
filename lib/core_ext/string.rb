require 'uuidtools'
class String
  def to_md5_uuid
      UUIDTools::UUID.md5_create(UUIDTools::UUID_DNS_NAMESPACE, self).to_s
  end
end
