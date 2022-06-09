# Таблица привязки техники и признака (sign)
class Binder < ApplicationRecord
  self.primary_key = :id
  self.table_name = "#{Rails.configuration.database_configuration["#{Rails.env}_invent"]['database']}.invent_binders"

  belongs_to :invent_item, class_name: 'Invent::Item', foreign_key: 'invent_item_id', optional: true
  belongs_to :warehouse_item, class_name: 'Warehouse::Item', foreign_key: 'warehouse_item_id', optional: true
  belongs_to :sign, class_name: 'Sign', foreign_key: 'sign_id', optional: false
end
