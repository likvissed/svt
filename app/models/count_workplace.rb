class CountWorkplace < Netadmin
  self.table_name   = :invent_count_workplace
  self.primary_key  = :count_workplace_id

  has_many :workplaces
  belongs_to :user_iss, class_name: 'UserIss', foreign_key: 'id_tn', optional: true

  after_validation :get_user_data, if: -> { self.errors[:tn].empty? }

  validates :division,    presence: true, numericality: { greater_than: 0, only_integer: true }, uniqueness: true
  validates :tn,          presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :count_wp,    presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :time_start,  presence: true
  validates :time_end,    presence: true

  enum status: { 'Разблокирован': 0, 'Заблокирован': 1 }, _prefix: :status

  attr_accessor :tn

  private

  # Получить данные об ответственном из БД Netadmin
  def get_user_data
    @user = UserIss.find_by(tn: self.tn)
    if @user.nil?
      self.errors.add(:tn, "информация по указанному табельному не найдена")
      return
    end

    self.id_tn = @user.id_tn
    self.phone = @user.tel if self.phone.empty?
  end
end