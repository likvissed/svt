class User < ApplicationRecord
  self.table_name = "#{Rails.configuration.database_configuration[Rails.env]['database']}.users"

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :trackable, :timeoutable, :omniauthable,
         omniauth_providers: %i[open_id_***REMOVED*** check_***REMOVED***_auth], authentication_keys: [:login]

  has_many :workplace_responsibles, class_name: 'Invent::WorkplaceResponsible', inverse_of: :user, dependent: :destroy
  has_many :workplace_counts, through: :workplace_responsibles, class_name: 'Invent::WorkplaceCount'

  belongs_to :role
  belongs_to :user_iss, foreign_key: 'id_tn'

  validates :tn, numericality: { only_integer: true }, presence: true, uniqueness: true, reduce: true
  validates :role, presence: true
  # validates :id_tn, uniqueness: { message: :tn_already_exists }
  validate :user_not_found, if: -> { errors.details.empty? }

  after_validation :replace_nil
  before_save :truncate_phone

  scope :fullname, ->(fullname) { where('fullname LIKE ?', "%#{fullname}%") }
  scope :role_id, ->(role_id) { where(role_id: role_id) }
  scope :online, ->(_attr) { where('sign_in_count > 0').where('updated_at > ?', online_time) }

  # Для тестов
  attr_accessor :login, :email, :division, :tel

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_hash).where(['tn = :value', { value: login }]).first
    elsif conditions.has_key?(:tn)
      where(conditions.to_hash).first
    end
  end

  # Время, в течении которого пользователь считается в состоянии online
  def self.online_time
    10.minutes.ago
  end

  def truncate_phone
    self.phone = phone.slice(0, 10)
  end

  # Проверка наличия указанной роли у пользователя
  # role_sym - символ имени роли
  def role?(role_sym)
    role.name.to_sym == role_sym
  end

  # Проверка наличия роли из указанного массива
  def one_of_roles?(*roles)
    roles.include?(role.name.to_sym)
  end

  def fill_data
    self.user_iss = UserIss.find_by(tn: tn)
    self.fullname = user_iss.try(:fio)
    self.phone = user_iss.try(:tel)
  end

  # Проверяет, в системе ли пользователь
  def online?
    updated_at > self.class.online_time && sign_in_count.positive?
  end

  def user_not_found
    return if UserIss.find_by(tn: tn)
    errors.add(:tn, :user_not_found, tn: tn)
  end

  protected

  def password_required?
    false
  end

  def email_required?
    false
  end

  def email_changed?
    false
  end

  private

  def replace_nil
    self.phone = '' if phone.nil?
  end
end
