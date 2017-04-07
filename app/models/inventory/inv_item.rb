module Inventory
  class InvItem < Invent
    self.primary_key  = :item_id
    self.table_name   = :invent_item

    has_many    :inv_property_values, -> { order(:property_id) }, foreign_key: 'item_id', dependent: :destroy,
                inverse_of: :inv_item
    belongs_to  :inv_type, foreign_key: 'type_id'
    belongs_to  :workplace, optional: true
    belongs_to  :inv_model, foreign_key: 'model_id'

    validates :type_id, presence: true, numericality: { greater_than: 0, only_integer: true, message: 'не выбран' }
    validates :invent_num, presence: true
    validate  :presence_model
    validate  :check_property_value

    before_save :set_default_model

    delegate :inv_properties, to: :inv_type

    accepts_nested_attributes_for :inv_property_values, allow_destroy: true, reject_if: :model_not_selected?

    private

    # Проверка наличия модели.
    def presence_model
      # Если модель не задана
      if (self.model_id.to_i.zero? && self.item_model.blank?) || self.model_id == -1
        self.errors.add(:model_id, 'не указана')
      end
    end

    # Валидации поля модели. Если валидация не пройдена, значит не нужно создавать inv_property_values.
    def model_not_selected?
      self.model_id == -1
    end

    def set_default_model
      self.model_id = nil if self.model_id.to_i.zero?
    end

    # Проверка наличия значений для всех свойств текущего экземпляра техники.
    def check_property_value
      # @properties = InvProperty.where('name IN (?)', %w{ mb ram video cpu hdd })
      @properties = InvProperty.all

      # Отдельная проверка для ПК, моноблока, ноутбука
      if InvPropertyValue::PROPERTY_WITH_FILES.include?(self.inv_type.name)
        # Предполагаем, что все параметры ПК заданы (далее в цикле проверяем, так ли это).
        # true - если все параметры заданы.
        # false - если хотя бы один параметр отсутствует.
        full_properties_flag  = true
        # Флаг наличия имени загружаемого файла
        # true - имя задано
        file_name_exist       = false

        inv_property_values.each do |prop_val|
          next if prop_val._destroy

          if %w{ mb ram video cpu hdd }.any? { |pc_prop| pc_prop == @properties.find { |prop| prop.property_id ==
            prop_val.property_id }.name }
            full_properties_flag = false if property_value_invalid?(prop_val)
            # Пропускаем тип свойства "config_file", так как его проверка будет последней, в конце метода.
          elsif @properties.find { |prop| prop.property_id == prop_val.property_id }.name == 'config_file'
            file_name_exist = true unless prop_val.value.blank?
          else
            add_prop_val_error(prop_val)
          end
        end

        # Проверка наличия данных от аудита, либо отчета о конфигурации
        if !self.invent_num.blank? && !full_properties_flag && !file_name_exist
          self.errors.add(:base, 'Необходимо добавить отчет о конфигурации, либо получить данные автоматически')
        end

      else
        inv_property_values.each do |prop_val|
          add_prop_val_error(prop_val)
        end
      end
    end

    # Добавить ошибку в объект errors, если значение свойства не прошло проверку.
    def add_prop_val_error(prop_val)
      self.errors.add(:base, "Не заполнено поле \"#{@properties.find { |prop| prop.property_id == prop_val.property_id }.short_description}\"") if
        property_value_invalid?(prop_val)
    end

    def property_value_invalid?(prop_val)
      (prop_val.property_list_id == -1 || (prop_val.property_list_id.to_i.zero? && prop_val.value.blank?)) && !prop_val._destroy
    end
  end
end