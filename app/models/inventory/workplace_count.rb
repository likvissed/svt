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
              uniqueness: { case_sensitive: false },
              reduce: true
    validates :time_start, presence: true
    validates :time_end, presence: true
    validate :at_least_one_responsible
    validate :forbid_duplicate_responsibles
    validate :user_existing

    accepts_nested_attributes_for :users, allow_destroy: true

    enum status: { 'Разблокирован': 0, 'Заблокирован': 1 }, _prefix: :status

    def users_attributes=(hash_arr)
      @role = Role.find_by(name: :***REMOVED***_user)

      hash_arr.each do |user_values|
        return if user_values[:tn].blank?
        @user_iss = UserIss.find_by(tn: user_values[:tn])

        # Если задан id пользователя.
        if user_values[:id]
          user = users.find { |user| user[:id] == user_values[:id] }

          # Если пользователя необходимо удалить из списка ответственных (сам пользователь не удалится).
          if user_values[:_destroy]
            user.mark_for_destruction
            next
          end

          user['phone'] = user_values[:phone].empty? ? @user_iss.tel : user_values[:phone]

        # Если id не задан, но пользователь существует в таблице 'users'.
        elsif user = User.where(tn: user_values[:tn]).first
          user.phone = user_values[:phone].empty? ? @user_iss.tel : user_values[:phone]
          user.fullname = @user_iss.fio

          users << user

        # Если создается новый пользователь.
        else
          if @user_iss
            users << User.new(
              id_tn: @user_iss.id_tn,
              fullname: @user_iss.fio,
              tn: user_values[:tn],
              phone: user_values[:phone].empty? ? @user_iss.tel : user_values[:phone],
              role: @role
            )
          else
            users.build(tn: user_values[:tn], role: @role)
          end
        end
      end
    end

    # Вывести ошибки модели workplace_responsibles.
    def wp_resp_errors
      workplace_responsibles.select { |wp_resp| wp_resp.errors.any? }.map { |wp_resp| wp_resp.errors.full_messages }
    end

    private

    # Проверка наличия ответственного.
    def at_least_one_responsible
      errors.add(:base, :add_at_least_one_responsible) if users.empty? && workplace_responsibles.empty?
      if users.reject { |resp| resp._destroy }.empty? && persisted?
        errors.add(:base, :save_at_least_one_responsible)
      end
    end

    # Проверка, не пытается ли пользователь создать двух одинаковых пользователей.
    def forbid_duplicate_responsibles
      user_count = {}
      users.each { |user| user_count[user.tn] = (user_count[user.tn] || 0) + 1 }

      user_count.each { |key, val| errors.add(:base, :multiple_user, tn: key) if val > 1 }
    end

    # Проверка, существует ли пользователь с указанным табельным номером.
    def user_existing
      user_errors = users.reject { |user| user.id_tn }.map(&:tn)

      errors.add(:base, :user_not_found, tn: user_errors.uniq.join(', ')) if user_errors.any?
    end
  end
end
