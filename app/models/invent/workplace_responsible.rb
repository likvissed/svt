module Invent
  class WorkplaceResponsible < BaseInvent
    self.table_name = "#{Rails.configuration.database_configuration["#{Rails.env}_invent"]['database']}.#{table_name_prefix}workplace_responsible"
    self.primary_key = :workplace_responsible_id

    belongs_to :workplace_count, inverse_of: :workplace_responsibles
    belongs_to :user, inverse_of: :workplace_responsibles

    validate :uniq_user_per_workplace_count

    def uniq_user_per_workplace_count
      if self.class.exists?(workplace_count: workplace_count, user: user) && new_record?
        errors.add(:user_id, :already_exists, tn: user.tn)
      end
    end
  end
end
