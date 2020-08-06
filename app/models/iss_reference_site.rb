class IssReferenceSite < Netadmin
  self.table_name = "#{Rails.configuration.database_configuration["#{Rails.env}_netadmin"]['database']}.iss_reference_sites"

  has_many :workplaces, class_name: 'Invent::Workplace', foreign_key: 'location_site_id'
  has_many :iss_reference_buildings, foreign_key: 'site_id'
  has_many :locations, class_name: 'Warehouse::Location', foreign_key: 'site_id'
end
