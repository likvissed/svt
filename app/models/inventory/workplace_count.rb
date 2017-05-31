module Inventory
  class WorkplaceCount < Invent
    self.table_name = "#{Rails.configuration.database_configuration["#{Rails.env}_invent"]['database']}.invent_workplace_count"

    self.primary_key = :workplace_count_id

    has_many :workplaces
    has_many :workplace_responsibles, dependent: :destroy, inverse_of: :workplace_count
    has_many :users, through: :workplace_responsibles

    validates :division,
              presence: true,
              numericality: { greater_than: 0, only_integer: true },
              uniqueness: true,
              reduce: true
    validates :time_start, presence: true
    validates :time_end, presence: true
    validate :at_least_one_responsible

    accepts_nested_attributes_for :users,
                                  allow_destroy: proc { |attr| Role.find(attr['role_id']) == '***REMOVED***_user' }

    enum status: { 'Разблокирован': 0, 'Заблокирован': 1 }, _prefix: :status

    private

    # Проверка наличия ответственного
    def at_least_one_responsible
      errors.add(:base, :add_at_least_one_responsible) if users.empty? && workplace_responsibles.empty?
      if users.reject { |resp| resp._destroy }.empty? && persisted?
        errors.add(:base, :save_at_least_one_responsible)
      end
    end
  end
end
