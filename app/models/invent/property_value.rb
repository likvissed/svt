module Invent
  class PropertyValue < BaseInvent
    self.primary_key = :property_value_id
    self.table_name = "#{table_name_prefix}property_value"

    has_one :standard_discrepancy, class_name: 'Standard::Discrepancy'

    belongs_to :property, optional: false
    belongs_to :item, optional: false
    belongs_to :property_list, optional: true

    validate :presence_val, if: -> { need_validation? && !skip_validations }

    before_save :set_default_property_list_id_to_nil

    attr_accessor :skip_validations

    def value
      if try(:property).try(:name) == 'ram' && super.present? && !super.match(/.* Гб/)
        "#{super} Гб"
      else
        super
      end
    end

    # Значение валидно, если:
    # - оно указано вручную или выбрано из списка
    # - оно необязательно
    def presence_val
      error = true

      case property.property_type
      when 'string'
        error = false if value.present?
      when 'list'
        error = false if property_list
      when 'list_plus'
        error = false if property_list || value.present?
      else
        error = false
        errors.add(:base, :unknown_property_type)
      end

      errors.add(:base, :blank, empty_prop: property.short_description) if error
    end

    # Удалить директорию, содержащую файл с конфигурацией ПК.
    def destroy_file
      raise 'abort' unless PcFile.new(property_value_id).destroy
    end

    protected

    def need_validation?
      return false if item.invent_num.blank?

      @pc_exceptions ||= PcException.pluck(:invent_num)
      # 1 - если инв. № относится к исключениям и при этом свойство также относится к исключениям - false
      # 2 - если свойство обязательно - true
      common_condition = !(Property::PROP_MANDATORY_EXCEPT.include?(property.name) && @pc_exceptions.any? { |s| s.casecmp(item.invent_num).zero? }) && property.mandatory

      # Если тип техники не относится к исключениям (Type::PRESENCE_MODEL_EXCEPT), добавить еще одно условие
      unless Type::PRESENCE_MODEL_EXCEPT.include?(item.type.name)
        common_condition &&= item.model_exists?
      end

      common_condition
    end

    def set_default_property_list_id_to_nil
      self.property_list_id = nil if property_list_id.to_i <= 0
    end
  end
end
