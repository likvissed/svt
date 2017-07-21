module Invent
  class InvPropertyValue < BaseInvent
    self.primary_key = :property_value_id
    self.table_name = "#{table_name_prefix}property_value"

    has_one :standart_discrepancy,
            class_name: 'Standart::Discrepancy',
            foreign_key: 'property_value_id',
            inverse_of: :inv_property_value

    belongs_to :inv_property, foreign_key: 'property_id'
    belongs_to :inv_item, foreign_key: 'item_id'
    belongs_to :inv_property_list, foreign_key: 'property_list_id'

    validates :property_id, presence: true, numericality: { greater_than: 0, only_integer: true, message: 'не указано' }
    # validate  :presence_value, if: -> { self.errors[:property_id].blank? }

    before_save :set_default_property_list_id_to_nil
    after_save :save_file, if: -> { :this_config_file? && !file.nil? }
    before_destroy :destroy_file, if: :this_config_file?
    after_initialize :set_default_property_list_id_to_zero

    # Переменная содержит объект файл, который необходимо записать в файловую систему.
    attr_accessor :file

    # Удалить директорию, содержащую файл с конфигурацией ПК.
    def destroy_file
      raise 'abort' unless PcFile.new(property_value_id).destroy
    end

    private

    def save_file
      raise 'abort' unless PcFile.new(property_value_id, file).upload
    end

    # Проверка наличия значений для свойства
    # def presence_value
    #   self.errors.add(:base, "Не заполнено поле \"#{self.inv_property.short_description}\"") unless
    #     property_value_valid?
    # end

    # def property_value_valid?
    #   !(self.property_list_id == -1 || (self.property_list_id.to_i.zero? && self.value.blank?))
    # end

    def set_default_property_list_id_to_nil
      self.property_list_id = nil if property_list_id.to_i <= 0
    end

    def set_default_property_list_id_to_zero
      self.property_list_id = 0 if property_list_id.nil?
    end

    # Проверка, является ли текущее свойство типом 'config_file'
    def this_config_file?
      inv_property.name == 'config_file'
    end
  end
end
