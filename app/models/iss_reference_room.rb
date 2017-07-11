class IssReferenceRoom < Netadmin
  self.table_name = "#{Rails.configuration.database_configuration["#{Rails.env}_netadmin"]['database']}.iss_reference_rooms"

  has_many :workplaces

  belongs_to :iss_reference_building, foreign_key: 'building_id'

  validates :name, presence: true
  validate :name_uniqueness_per_building

  private

  # Валидация, проверяющая уникальность номера комнаты в рамках текущего workplace_count.
  def name_uniqueness_per_building
    errors.add(:name, "Комната '#{name}' уже существует") if self.class.exists?(iss_reference_building:
      iss_reference_building, name: name)
  end
end
