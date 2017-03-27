class WorkplaceSpecialization < Invent
  self.table_name   = :invent_workplace_specialization
  self.primary_key  = :workplace_specialization_id

  has_many :workplaces
end