class HostIss < Netadmin
  self.table_name = :hosts
  self.primary_key = :ip

  def self.get_host(inv_num)
    data = connection.exec_query("SELECT * FROM #{table_name} WHERE id = #{sanitize(inv_num.to_s)}").first
    data.nil? ? nil : data.symbolize_keys
  end
end
