module Invent
  class WorkplaceCount < BaseInvent
    self.table_name = 'invent_workplace_count'
    self.primary_key = 'workplace_count_id'

    has_many :workplaces, dependent: :restrict_with_error
    has_many :workplace_responsibles, dependent: :destroy
    has_many :users, through: :workplace_responsibles
  end
end