class HostIss < Netadmin
  self.table_name = :hosts
  self.primary_key = :ip

  # def self.get_pcs(start)
  #   self.connection.exec_query("SELECT h.id AS id, h.tn AS tn, h.room AS room, name, ui.dept AS division
  #               FROM #{self.table_name} h, #{UserISS.table_name} ui
  #               WHERE h.tn = ui.tn AND cms = 1
  #               ORDER BY name LIMIT #{start}, #{10}")
  # end

  def self.get_host(inv_num)
    data = connection.exec_query("SELECT * FROM #{table_name} WHERE id = #{sanitize(inv_num.to_s)}").first
    data.nil? ? nil : data.with_indifferent_access
  end
end
