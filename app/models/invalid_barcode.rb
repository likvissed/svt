class InvalidBarcode < ApplicationRecord
  self.table_name = "#{Rails.configuration.database_configuration["#{Rails.env}_invent"]['database']}.invent_invalid_barcodes"
  self.primary_key = :id

  belongs_to :invent_item, class_name: 'Invent::Item', foreign_key: 'item_id'
end
