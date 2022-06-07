class Sign < ApplicationRecord
  self.primary_key = :sign_id
  self.table_name = "#{Rails.configuration.database_configuration["#{Rails.env}_invent"]['database']}.invent_signs"

  has_many :binders, class_name: 'Binder', foreign_key: 'sign_id'
end
