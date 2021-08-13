module Invent
  class Type < BaseInvent
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
    # Список типов оборудования, которые имеют свойство с типом "файл" и хранят конфигурацию оборудования (Property::FILE_DEPENDING)
    TYPE_WITH_FILES = %w[pc allin1 notebook].freeze
    # Список типов оборудования, которые не могут быть включены в состав серверного РМ
    REJECTED_SERVER_TYPES = %w[notebook tablet].freeze
    # Типы оборудования, которые могут регистрироваться в сети
    NAME_TYPE_OF_HOST = %w[pc printer mfu print_server ups allin1 notebook].freeze
    # Типы техники, для которых поле "Серийный номер" является обязательным при выдачи на РМ
    NAME_FOR_MANDATORY_SERIAL_NUM = %w[monitor allin1 notebook mfu printer tablet tv].freeze
    # Типы техники, которые могут отправляться на разрегистрацию техники (UnregistrationWorker)
    NAME_FOR_UNREGISTRATION_ITEM = %w[pc printer plotter mfu print_server allin1 notebook tablet print_system].freeze

    has_many :items, dependent: :destroy
    has_many :property_to_types, dependent: :destroy
    has_many :properties, -> { order(:property_order) }, through: :property_to_types
    has_many :models, -> { order(:item_model) }, dependent: :destroy
    has_many :vendors, through: :models
  end
end
