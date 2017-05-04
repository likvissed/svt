class IssReferenceSite < Netadmin
  has_many :workplaces
  has_many :iss_reference_buildings, foreign_key: 'site_id'
end
