class WorkplaceCount < Invent
  self.table_name   = :invent_workplace_count
  self.primary_key  = :workplace_count_id

  has_many :workplaces
  has_many :workplace_responsibles, dependent: :destroy, inverse_of: :workplace_count
  has_many :user_isses, through: :workplace_responsibles

  before_validation :set_user_data_in_nested_attrs

  validates :division,    presence: true, numericality: { greater_than: 0, only_integer: true }, uniqueness: true
  validates :time_start,  presence: true
  validates :time_end,    presence: true
  validate  :at_least_one_responsible

  accepts_nested_attributes_for :workplace_responsibles, allow_destroy: true, reject_if: proc { |attr| attr['tn'].blank? }

  enum status: { 'Разблокирован': 0, 'Заблокирован': 1 }, _prefix: :status

  # Для работы  метода get_user_data
  attr_accessor :id_tn, :phone

  private

  # Проверка наличия ответственного
  def at_least_one_responsible
    return self.errors.add(:base, "Необходимо добавить ответственного") unless workplace_responsibles.length > 0
    return self.errors.add(:base, "Необходимо оставить хотя бы одного ответственного") if workplace_responsibles.reject{
      |resp| resp._destroy == true }.empty?
  end

  # Установить знчения переменных id_tn и phone для вложенных аттрибутов
  def set_user_data_in_nested_attrs
    workplace_responsibles.each do |resp|
      get_user_data(resp.tn)

      resp.id_tn = self.id_tn
      resp.phone = self.phone if resp.phone.empty?
    end
  end

  # Получить данные об ответственном из БД Netadmin
  def get_user_data(tn)
    @user = UserIss.find_by('tn = ?', tn)

    if @user.nil?
      self.errors.add(:base, "Информация по табельному #{tn} не найдена")
      return
    end

    self.id_tn = @user.id_tn
    self.phone = @user.tel
  end
end