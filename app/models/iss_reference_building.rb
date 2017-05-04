class IssReferenceBuilding < Netadmin
  has_many :workplaces
  has_many :iss_reference_rooms, foreign_key: 'building_id'

  belongs_to :iss_reference_site, foreign_key: 'site_id'
end
