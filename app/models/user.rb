class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :trackable, :timeoutable, :omniauthable,
         omniauth_providers: %i[open_id_***REMOVED*** check_***REMOVED***_auth], authentication_keys: [:login]

  has_many :workplace_responsibles, class_name: 'Invent::WorkplaceResponsible', inverse_of: :user
  has_many :workplace_counts, through: :workplace_responsibles, class_name: 'Invent::WorkplaceCount'

  belongs_to :role
  belongs_to :user_iss, foreign_key: 'id_tn'

  validates :tn, presence: true, uniqueness: true
  validates :role, presence: true
  # validates :id_tn, uniqueness: { message: :tn_already_exists }

  after_validation :replace_nil
  before_save :truncate_phone

  # Для тестов.
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
  def has_role?(role_sym)
    role.name.to_sym == role_sym
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
