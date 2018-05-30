module Invent
  class WorkplaceSpecialization < BaseInvent
    self.primary_key = :workplace_specialization_id
    self.table_name = "#{table_name_prefix}workplace_specialization"

    has_many :workplaces, dependent: :restrict_with_error
  end
end
