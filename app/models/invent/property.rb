module Invent
  class Property < BaseInvent
    self.primary_key = :property_id
    self.table_name = "#{table_name_prefix}property"

    # Свойства ПК, которые должны быть заполнены из утилиты SysConfig
    FILE_DEPENDING = %w[mb ram video cpu hdd].freeze
    # Свойства, которые не обязательны для заполнения в случае, если для текущего экземпляра техники указан инвентарный
    # номер, который встречается в модели PcException.
    PROP_MANDATORY_EXCEPT = %w[network_connection mb ram video cpu hdd].freeze

    has_many :property_to_types, dependent: :destroy
    has_many :types, through: :property_to_types
    has_many :property_values, dependent: :destroy
    has_many :property_lists, dependent: :destroy
    has_many :model_property_lists, dependent: :restrict_with_error
  end
end
