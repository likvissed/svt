class Barcode < ApplicationRecord
  self.table_name = "#{Rails.configuration.database_configuration[Rails.env]['database']}.barcodes"

  belongs_to :codeable, polymorphic: true

  validates :codeable_type, presence: true
  validate :uniqueness_type_and_id

  def uniqueness_type_and_id
    errors.add(:base, :barcode_already_exists, codeable_id: codeable_id) if self.class.exists?(codeable_type: codeable_type, codeable_id: codeable_id)
  end
end
