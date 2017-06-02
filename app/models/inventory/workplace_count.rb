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
    validate :forbid_duplicate_responsibles
    validate :user_existing

    accepts_nested_attributes_for :users,
                                  allow_destroy: proc { |attr| Role.find(attr['role_id']) == '***REMOVED***_user' }

    enum status: { 'Разблокирован': 0, 'Заблокирован': 1 }, _prefix: :status

    def users_attributes=(hash)
      hash.each do |user_values|
        if user = User.where(tn: user_values[:tn]).first
          user.phone = user_values[:phone].empty? ? UserIss.find_by(tn: user.tn).tel : user_values[:phone]
        else
          user = User.new(user_values)
        end

        self.users << user
        # self.users << User.where(tn: user_values[:tn]).first_or_initialize(user_values)
      end
    end

    private

    # Проверка наличия ответственного
    def at_least_one_responsible
      errors.add(:base, :add_at_least_one_responsible) if users.empty? && workplace_responsibles.empty?
      if users.reject { |resp| resp._destroy }.empty? && persisted?
        errors.add(:base, :save_at_least_one_responsible)
      end
    end

    # Проверка, не пытается ли пользователь создать двух одинаковых пользователей
    def forbid_duplicate_responsibles
      user_count = {}
      users.each { |user| user_count[user.tn] = (user_count[user.tn] || 0) + 1 }

      user_count.each { |key, val| errors.add(:base, :multiple_user, tn: key) if val > 1 }
    end

    def user_existing
      user_errors = []
      users.each { |user| user_errors << user.tn unless user.id_tn }

      errors.add(:base, :user_not_found, tn: user_errors.uniq.join(', ')) if user_errors.any?
    end
  end
end
