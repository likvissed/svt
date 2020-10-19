class Barcode < ApplicationRecord
  self.table_name = "#{Rails.configuration.database_configuration[Rails.env]['database']}.barcodes"

  belongs_to :codeable, polymorphic: true
end
