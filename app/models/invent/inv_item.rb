module Invent
  class InvItem < BaseInvent
    self.primary_key = :item_id
    self.table_name = "#{table_name_prefix}item"

    has_many :inv_property_values,
             -> { joins('LEFT OUTER JOIN invent_property ON invent_property_value.property_id = invent_property.property_id').order('invent_property.property_order') },
             foreign_key: 'item_id',
             dependent: :destroy,
             inverse_of: :inv_item
    has_many :inv_properties, -> { order('invent_property.property_order') }, through: :inv_property_values
    has_many :standard_discrepancies,
             class_name: 'Standard::Discrepancy',
             foreign_key: 'item_id',
             dependent: :destroy,
             inverse_of: :inv_item
    has_many :standard_logs, class_name: 'Standard::Log', foreign_key: 'item_id', inverse_of: :inv_item

    belongs_to :inv_type, foreign_key: 'type_id'
    belongs_to :workplace, optional: true
    belongs_to :inv_model, foreign_key: 'model_id'

    validates :type_id, presence: true, numericality: { greater_than: 0, only_integer: true }
    validates :invent_num, presence: true
    validate :presence_model, unless: -> { errors.details[:type_id].any? }
    validate :check_property_value, unless: -> { errors.details[:type_id].any? }
    validate :check_mandatory, unless: -> { errors.details[:type_id].any? }

    before_save :set_default_model

    delegate :inv_properties, to: :inv_type

    accepts_nested_attributes_for :inv_property_values, allow_destroy: true, reject_if: :model_not_selected?

    private

    # Проверка наличия модели.
    def presence_model
      # Если модель не задана
      if ((model_id.to_i.zero? && item_model.blank?) || model_id == -1) &&
         !InvType::PRESENCE_MODEL_EXCEPT.include?(inv_type.name)
        errors.add(:model_id, :blank)
      end
    end

    # Валидации поля модели. Если валидация не пройдена, значит не нужно создавать inv_property_values.
    def model_not_selected?
      model_id == -1
    end

    def set_default_model
      self.model_id = nil if model_id.to_i.zero?
    end

    # Проверка наличия значений для всех свойств текущего экземпляра техники.
    def check_property_value
      @pc_exceptions ||= InvPcException.pluck(:invent_num)
      @properties ||= inv_type.inv_properties

      # Отдельная проверка для ПК, моноблока, ноутбука
      if InvType::TYPE_WITH_FILES.include?(inv_type.name) && !@pc_exceptions.any? { |s| s.casecmp(invent_num) == 0 }
        flags = prop_values_verification

        # Проверка наличия данных от аудита
        if invent_num.present? && !flags[:full_properties_flag]
          # Проверку отчета о конфигурации отключил, так как теперь расшифровка происходит на стороне сервера. Класс,
          # обрабатывающий файл, не проверяет, валиден ли файл, он просто возвращает данные (какими бы они не были).
          # Если ошибка с данными, нужно править программу SysInfo.
          # && !flags[:file_name_exist]
          errors.add(:base, :pc_data_not_received)
        end

        # Если имя файла пришло пустым (не будет работать при создании нового item, только во время редактирования).
        config_file_verification unless flags[:file_name_exist]
      elsif InvType::TYPE_WITH_FILES.include?(inv_type.name) && @pc_exceptions.any? { |s| s.casecmp(invent_num) == 0 }
        exception_pc_prop_values_verification
      else
        inv_property_values.each { |prop_val| prop_value_verification(prop_val) }
      end
    end

    # Проверка, что все properties со свойством "mandatory: true" присутствуют.
    def check_mandatory
      @properties ||= inv_type.inv_properties

      @properties.where(mandatory: true).each do |prop|
        unless inv_property_values.reject(&:_destroy).find { |prop_val| prop_val[:property_id] == prop.property_id }
          errors.add(:base, :property_not_filled, empty_prop: prop.short_description)
        end
      end
    end

    # Проверка, заполнены ли значения для свойств техники, исключая те, что указаны в InvProperty::PC_EXCEPT.
    def exception_pc_prop_values_verification
      inv_property_values.each do |prop_val|
        next if prop_val._destroy || InvProperty::PC_EXCEPT.any? do |pc_prop|
          pc_prop == @properties.find { |prop| prop.property_id == prop_val.property_id }.name
        end

        prop_value_verification(prop_val)
      end
    end

    # Проверка, заполнены ли значения для всех свойств техники.
    def prop_values_verification
      flags = {
        # Предполагаем, что все параметры ПК заданы (далее в цикле проверяем, так ли это).
        # true - все параметры заданы.
        # false - хотя бы один параметр отсутствует.
        full_properties_flag: true,
        # Флаг наличия имени загружаемого файла
        # true - имя задано
        file_name_exist: false
      }

      inv_property_values.each do |prop_val|
        next if prop_val._destroy

        # Ищем совпадения с именами свойства системного блока.
        founded_prop = InvProperty::FILE_DEPENDING.any? do |pc_prop|
          pc_prop == @properties.find { |prop| prop.property_id == prop_val.property_id }.name
        end

        if founded_prop
          flags[:full_properties_flag] = false unless property_value_valid?(prop_val)
          # Пропускаем тип свойства "config_file", так как его проверка будет последней, в конце метода.
        elsif @properties.find { |prop| prop.property_id == prop_val.property_id }.name == 'config_file'
          flags[:file_name_exist] = true if prop_val.value.present?
        else
          prop_value_verification(prop_val)
        end
      end

      flags
    end

    # Удалить старый файл конфигурации, если был загружен новый.
    def config_file_verification
      # Объект свойства 'config_file'
      prop_obj = @properties.find { |prop| prop.name == 'config_file' }
      # Объект inv_property_value со свойством 'config_file'
      file_obj = inv_property_values.find { |val| val.property_id == prop_obj.property_id }

      # Если имя файла изменилось и при этом ранее имя файла было указано (а сейчас оно отсутствует), файл
      # необходимо удалить из файловой системы.
      return unless file_obj&.value_changed? && !file_obj.value_was.to_s.empty?
      logger.info 'Вызов метода для удаления файла'
      file_obj.destroy_file
    end

    # Добавить ошибку в объект errors, если значение свойства не прошло проверку.
    def prop_value_verification(prop_val)
      return if property_value_valid?(prop_val)

      field = @properties.find { |prop| prop.property_id == prop_val.property_id }.short_description
      errors.add(:base, :field_is_empty, empty_field: field)
    end

    def property_value_valid?(prop_val)
      # Флаг, показывающий, нужно ли в условии проверять свойство mandatory. Этот флаг необходим, так как для свойств
      # ПК, моноблока и ноутбука основные параметры могут зависеть от передаваемого файла.
      escape_mandatory = InvProperty::PC_EXCEPT.any? do |pc_prop|
        pc_prop == @properties.find { |prop| prop.property_id == prop_val.property_id }.name
      end

      if escape_mandatory
        (prop_val.property_list_id != -1 && (!prop_val.property_list_id.to_i.zero? || prop_val.value.present?)) || prop_val._destroy
      else
        (prop_val.property_list_id != -1 && (!prop_val.property_list_id.to_i.zero? || prop_val.value.present?) || !prop_val.inv_property.mandatory) || prop_val._destroy
      end
    end
  end
end
