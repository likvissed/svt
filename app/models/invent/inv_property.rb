module Invent
  class InvProperty < BaseInvent
    self.primary_key = :property_id
    self.table_name = "#{table_name_prefix}property"

    # Свойства ПК, которые могут быть заполнены из загруженного файла
    FILE_DEPENDING = %w[mb ram video cpu hdd].freeze
    # Свойства, которые не обязательны для заполнения в случае, если для текущего экземпляра техники указан инвентарный
    # номер, который встречается в модели InvPcException.
    PC_EXCEPT = %w[network_connection mb ram video cpu hdd config_file].freeze

    has_many :inv_property_values, foreign_key: 'property_id', dependent: :destroy
    has_many :inv_property_lists, foreign_key: 'property_id', dependent: :destroy
    has_many :inv_property_to_types, foreign_key: 'property_id', dependent: :destroy
    has_many :inv_types, through: :inv_property_to_types
    has_many :inv_model_property_lists, foreign_key: 'property_id'
  end
end
