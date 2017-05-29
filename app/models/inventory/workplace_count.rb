module Inventory
  class WorkplaceCount < Invent
    self.table_name = "#{Rails.configuration.database_configuration["#{Rails.env}_invent"]['database']}.invent_workplace_count"

    self.primary_key = :workplace_count_id

    has_many :workplaces
    has_many :workplace_responsibles, dependent: :destroy, inverse_of: :workplace_count
    has_many :users, through: :workplace_responsibles

    before_validation :set_user_data_in_nested_attrs

    validates :division, presence: true, numericality: { greater_than: 0, only_integer: true }, uniqueness: true
    validates :time_start, presence: true
    validates :time_end, presence: true
    validate  :at_least_one_responsible

    accepts_nested_attributes_for :workplace_responsibles, allow_destroy: true, reject_if: proc { |attr| attr['tn'].blank? }

    enum status: { 'Разблокирован': 0, 'Заблокирован': 1 }, _prefix: :status

    # Для работы  метода get_user_data
    attr_accessor :id_tn, :phone, :local_user

    private

    # Проверка наличия ответственного
    def at_least_one_responsible
      errors.add(:base, 'Необходимо добавить ответственного') if workplace_responsibles.empty?
      if workplace_responsibles.reject { |resp| resp._destroy == true }.empty? && persisted?
        errors.add(:base, 'Необходимо оставить хотя бы одного ответственного')
      end
    end

    # Установить знчения переменных id_tn и phone для вложенных аттрибутов
    def set_user_data_in_nested_attrs
      workplace_responsibles.each do |resp|
        get_user_data(resp.tn)

        resp.user_id = @local_user.id
      end
    end

    # Получить данные об ответственном из БД Netadmin
    def get_user_data(tn)
      @user = UserIss.find_by('tn = ?', tn)

      if @user.nil?
        errors.add(:base, "Информация по табельному #{tn} не найдена")
        return
      end

      @local_user = User.find_by(id_tn: @user.id_tn)
      if @local_user.nil?
        @local_user = User.create({
          tn: tn,
          id_tn: @user.id_tn,
          role: Role.find_by(name: :***REMOVED***_user)
        })
      end

      self.id_tn = @user.id_tn
      self.phone = @user.tel
    end
  end
end
