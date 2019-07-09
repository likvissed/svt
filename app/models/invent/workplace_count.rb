module Invent
  class WorkplaceCount < BaseInvent
    self.table_name = 'invent_workplace_count'
    self.primary_key = 'workplace_count_id'

    has_many :workplaces, dependent: :restrict_with_error
    has_many :workplace_responsibles, dependent: :destroy
    has_many :users, through: :workplace_responsibles

    accepts_nested_attributes_for :users, reject_if: proc { |attributes| attributes['tn'].blank? }

    scope :division, ->(division) { where(division: division) }
    scope :responsible_fullname, ->(responsible_fullname) { left_outer_joins(:users).where('fullname LIKE ?', "%#{responsible_fullname}%") }

    validates :division, :time_start, :time_end, presence: true
    validates :division, uniqueness: true, numericality: { only_integer: true }
    validate :add_at_least_one_responsible, if: -> { users.blank? && workplace_responsibles.blank? }

    def add_at_least_one_responsible
      errors.add(:base, :add_at_least_one_responsible)
    end
  end
end
