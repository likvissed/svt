class BindingSign < ApplicationRecord
  self.table_name = "#{Rails.configuration.database_configuration["#{Rails.env}_invent"]['database']}.invent_bindings"
  self.primary_key = :id

  belongs_to :sign, class_name: 'Invent::Sign', foreign_key: 'invent_sign_id', optional: false
  belongs_to :bindable, polymorphic: true

  validates :bindable_type, presence: true
end
