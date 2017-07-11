class IssReferenceSite < Netadmin
  self.table_name = "#{Rails.configuration.database_configuration["#{Rails.env}_netadmin"]['database']}.iss_reference_sites"
  
  has_many :workplaces
  has_many :iss_reference_buildings, foreign_key: 'site_id'
end
