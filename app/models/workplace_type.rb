class WorkplaceType < Invent
  self.primary_key  = :workplace_type_id
  self.table_name   = :invent_workplace_type

  has_many :workplaces, dependent: :restrict_with_error
end
