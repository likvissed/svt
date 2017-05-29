module Inventory
  class WorkplaceResponsible < Invent
    self.table_name = "#{Rails.configuration.database_configuration["#{Rails.env}_invent"]['database']}.invent_workplace_responsible"
    self.primary_key = :workplace_responsible_id

    belongs_to :workplace_count, inverse_of: :workplace_responsibles
    belongs_to :user

    validate :tn_uniqueness_per_workplace_count

    attr_accessor :tn

    private

    # Валидация, проверяющая уникальность табельного номера в рамках текущего workplace_count.
    def tn_uniqueness_per_workplace_count
      errors.add(:tn, "'#{tn}' уже существует") if self.class.exists?(workplace_count: workplace_count, id_tn:
        id_tn, phone: phone)
    end
  end
end
