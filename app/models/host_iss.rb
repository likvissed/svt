class HostIss < Netadmin
  self.table_name = :hosts
  self.primary_key = :ip

  bad_attribute_names :class
  alias_attribute :invent_num, :id

  def klass
    read_attribute(:class)
  end

  def klass=(val)
    write_attribute(:class, val)
  end
end
