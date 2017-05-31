module Inventory
  class WorkplaceResponsible < Invent
    self.table_name = "#{Rails.configuration.database_configuration["#{Rails.env}_invent"]['database']}.invent_workplace_responsible"
    self.primary_key = :workplace_responsible_id

    belongs_to :workplace_count, inverse_of: :workplace_responsibles
    belongs_to :user, inverse_of: :workplace_responsibles

    validates :user_id, uniqueness: { scope: :workplace_count_id, message: :already_exists }
  end
end
