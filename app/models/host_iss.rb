class HostIss < Netadmin
  self.table_name   = :hosts
  self.primary_key  = :ip

  # def self.get_pcs(start)
  #   self.connection.exec_query("SELECT h.id AS id, h.tn AS tn, h.room AS room, name, ui.dept AS division
  #               FROM #{self.table_name} h, #{UserISS.table_name} ui
  #               WHERE h.tn = ui.tn AND cms = 1
  #               ORDER BY name LIMIT #{start}, #{10}")
  # end

  def self.get_host(inv_num)
    self.connection.exec_query("SELECT * FROM #{self.table_name} WHERE id = #{self.sanitize(inv_num)}").first
  end
end