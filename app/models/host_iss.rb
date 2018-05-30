class HostIss < Netadmin
  self.table_name = :hosts
  self.primary_key = :ip

  bad_attribute_names :class
  alias_attribute :invent_num, :id

  def self.by_invent_num(invent_num)
    sql = "SELECT * FROM hosts WHERE id = ?;"
    connection.select_all(
      send(:sanitize_sql_array, [sql, invent_num])
    ).to_hash.first
  end

  def klass
    read_attribute(:class)
  end

  def klass=(val)
    write_attribute(:class, val)
  end
end
