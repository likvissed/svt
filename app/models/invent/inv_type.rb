module Invent
  class InvType < BaseInvent
    self.primary_key = :type_id
    self.table_name = "#{table_name_prefix}type"

    # Типы оборудования, для которых не обязательно наличие модели.
    PRESENCE_MODEL_EXCEPT = %w[pc].freeze
    # Типы оборудования, разрешенные для установки на мобильном рабочем месте.
    ALLOWED_MOB_TYPES = %w[notebook tablet].freeze
    # Типы ПК, которые не могут встречаться дважды в одном РМ.
    SINGLE_PC_ITEMS = %w[pc allin1 notebook tablet].freeze
    # Все типы печатающих устройств, у которых можно выбрать тип подключения.
    ALL_PRINT_TYPES = %w[printer plotter scanner mfu copier print_system].freeze
    # Список типов оборудования, которые имеют свойство с типом "файл" и хранят конфигурацию оборудования (InvProperty::FILE_DEPENDING)
    TYPE_WITH_FILES = %w[pc allin1 notebook].freeze

    has_many :inv_items, foreign_key: 'type_id', dependent: :destroy, inverse_of: :inv_type

    has_many :inv_property_to_types, foreign_key: 'type_id', dependent: :destroy
    has_many :inv_properties, -> { order(:property_order) }, through: :inv_property_to_types

    has_many :inv_models, foreign_key: 'type_id'
    has_many :inv_vendors, through: :inv_models
  end
end
