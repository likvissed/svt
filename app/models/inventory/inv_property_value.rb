module Inventory
  class InvPropertyValue < Invent
    self.primary_key = :property_value_id
    self.table_name = :invent_property_value

    # Список типов оборудования, которые имеют свойство с типом "файл"
    PROPERTY_WITH_FILES = %w[pc allin1 notebook].freeze

    belongs_to :inv_property, foreign_key: 'property_id'
    belongs_to :inv_item, foreign_key: 'item_id'
    belongs_to :inv_property_list, foreign_key: 'property_list_id'

    validates :property_id, presence: true, numericality: { greater_than: 0, only_integer: true, message: 'не указано' }
    # validate  :presence_value, if: -> { self.errors[:property_id].blank? }

    before_save :set_default_property_list_id_to_nil
    before_destroy :destroy_file, if: :this_config_file?
    after_initialize :set_default_property_list_id_to_zero

    # Удалить директорию, содержащую файл с конфигурацией ПК.
    def destroy_file
      path_to_file = Rails.root.join('public', 'uploads', property_value_id.to_s)
      begin
        logger.info "Удаление директории: #{path_to_file}".red
        FileUtils.rm_r(path_to_file) if File.exist?(path_to_file)
      rescue
        # self.errors.add(:base, 'Не удалось удалить файл. Обратитесь к администратору')
        throw(:abort)
      end
    end

    private

    # Проверка наличия значений для свойства
    # def presence_value
    #   self.errors.add(:base, "Не заполнено поле \"#{self.inv_property.short_description}\"") unless
    #     property_value_valid?
    # end

    # def property_value_valid?
    #   !(self.property_list_id == -1 || (self.property_list_id.to_i.zero? && self.value.blank?))
    # end

    def set_default_property_list_id_to_nil
      self.property_list_id = nil if property_list_id.to_i.zero?
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
