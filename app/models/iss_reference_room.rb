class IssReferenceRoom < Netadmin
  self.table_name = "#{Rails.configuration.database_configuration["#{Rails.env}_netadmin"]['database']}.iss_reference_rooms"

  has_many :workplaces, class_name: 'Invent::Workplace', foreign_key: 'location_room_id'

  belongs_to :iss_reference_building, foreign_key: 'building_id'
  belongs_to :room_security_category, foreign_key: 'security_category_id'

  validates :name, presence: true
  validates :security_category_id, presence: true

  validate :name_uniqueness_per_building

  private

  # Валидация, проверяющая уникальность номера комнаты в рамках текущего workplace_count.
  def name_uniqueness_per_building
    errors.add(:name, "Комната '#{name}' уже существует") if self.class.exists?(iss_reference_building:
      iss_reference_building, name: name, security_category_id: security_category_id)
  end
end
