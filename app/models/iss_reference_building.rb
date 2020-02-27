class IssReferenceBuilding < Netadmin
  self.table_name = "#{Rails.configuration.database_configuration["#{Rails.env}_netadmin"]['database']}.iss_reference_buildings"

  has_many :workplaces, class_name: 'Invent::Workplace', foreign_key: 'location_building_id'
  has_many :workplace_counts, through: :workplaces, class_name: 'Invent::WorkplaceCount'
  has_many :iss_reference_rooms, foreign_key: 'building_id'
  has_many :locations, class_name: 'Warehouse::Location', foreign_key: 'building_id'

  belongs_to :iss_reference_site, foreign_key: 'site_id'
end
