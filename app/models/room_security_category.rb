class RoomSecurityCategory < Netadmin
  self.table_name = "#{Rails.configuration.database_configuration["#{Rails.env}_netadmin"]['database']}.room_security_categories"

  has_many :iss_reference_room, foreign_key: 'security_category_id'
end
