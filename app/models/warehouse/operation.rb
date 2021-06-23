module Warehouse
  class Operation < BaseWarehouse
    self.table_name = "#{table_name_prefix}operations"

    has_many :inv_item_to_operations, dependent: :destroy
    has_many :inv_items, through: :inv_item_to_operations, class_name: 'Invent::Item'

    belongs_to :item, optional: true, autosave: true
    belongs_to :stockman, class_name: 'UserIss', foreign_key: 'stockman_id_tn', optional: true
    belongs_to :operationable, polymorphic: true

    validates :item_type, :item_model, :shift, :status, presence: true
    validates :shift, numericality: { other_than: 0 }
    validates :stockman_fio, :date, presence: true, if: -> { done? }
    validate :uniq_item_by_processing_operation, if: -> { item.try(:used?) && item_id_changed? }
    validate :presence_warehouse_receiver_fio, if: -> { presence_w_receiver_fio == true && operationable.try(:operation) == 'out' && done? }
    validate :check_worker_w_receiver_fio, if: -> { worker_w_receiver_fio == true && warehouse_receiver_fio_changed? }

    after_initialize :set_initial_status, if: -> { new_record? }
    after_initialize :set_initial_shift, if: -> { new_record? }
    before_validation :set_date, if: -> { done? && status_changed? }
    before_update :prevent_change_status
    before_update :prevent_update
    before_destroy :prevent_destroy, if: -> { done? }

    accepts_nested_attributes_for :inv_items, allow_destroy: false

    enum status: { processing: 1, done: 2 }

    attr_accessor :to_write_off, :update_item_without_invent_num

    # Для проверки поля принявшего технику со склада
    attr_accessor :presence_w_receiver_fio
    # Для проверки
    attr_accessor :worker_w_receiver_fio

    def set_stockman(user)
      self.stockman_id_tn = user.id_tn
      self.stockman_fio = user.fullname
    end

    def done?
      status == 'done'
    end

    def processing?
      status == 'processing'
    end

    def formatted_date
      date&.strftime('%d-%m-%Y')
    end

    def build_inv_items(count, **params)
      return if item.warehouse_type == 'without_invent_num'

      count.times do |i|
        if item.inv_item
          change_inv_item(params[:status], params[:workplace])
        else
          new_inv_item = inv_items.build(
            type: item.inv_type,
            workplace: params[:workplace],
            model: item.inv_model,
            item_model: item.item_model,
            invent_num: item.generate_invent_num(i),
            status: params[:status]
          )
          new_inv_item.build_barcode_item

          new_inv_item.build_property_values(item, true)
        end
      end
    end

    def change_inv_item(status, workplace = nil)
      return unless item.warehouse_type == 'with_invent_num' && item.inv_item

      item.inv_item.status = status
      item.inv_item.workplace = workplace
      inv_items << item.inv_item
    end

    def calculate_item_count_reserved
      if new_record?
        item.count_reserved += shift.abs
      elsif marked_for_destruction?
        item.count_reserved -= shift.abs
      elsif shift_changed?
        delta = shift_was - shift
        item.count_reserved += delta
      elsif status_changed? && done?
        item.count_reserved += shift
      end

      # Чтобы не было отрицательного значения в count_reserved
      item.count_reserved = 0 if item.count_reserved.negative?
    end

    def calculate_item_count
      if new_record? || (status_changed? && done?)
        item.count += shift
      elsif marked_for_destruction?
        item.count -= shift
      elsif shift_changed?
        delta = shift - shift_was
        item.count += delta
      end
    end

    def calculate_item_invent_num_end
      return if item.warehouse_type != 'with_invent_num' || item.invent_num_start.nil?

      if new_record?
        item.invent_num_end = item.invent_num_start + shift - 1
      elsif marked_for_destruction?
        item.invent_num_end -= shift - 1
      elsif shift_changed?
        delta = shift - shift_was
        item.invent_num_end += delta
      elsif item.invent_num_start_changed?
        item.invent_num_end = item.invent_num_start + shift - 1
      end
    end

    protected

    def set_initial_status
      self.status ||= :processing
    end

    def set_initial_shift
      self.shift ||= operationable.try(:operation) == 'out' ? -1 : 1
    end

    def uniq_item_by_processing_operation
      op = item.operations.find(&:processing?)
      return unless op

      if item.inv_item
        errors.add(
          :base,
          :operation_with_invent_num_already_exists,
          type: item.item_type,
          invent_num: item.inv_item.invent_num,
          order_id: op.operationable.id
        )
      else
        errors.add(
          :base,
          :operation_without_invent_num_already_exists,
          type: item.item_type,
          model: item.item_model,
          order_id: op.operationable.id
        )
      end
    end

    def set_date
      self.date = Time.zone.now
    end

    def prevent_change_status
      return unless status_was == 'done' && processing?

      errors.add(:base, :cannot_cancel_done_operation)
      throw(:abort)
    end

    def prevent_update
      return true if update_item_without_invent_num.present?

      return true unless done? && !status_changed?
      # Для операций с поставки техники со штрих-кодом
      return true if operationable_type == 'Warehouse::Supply'

      errors.add(:base, :cannot_update_done_operation)
      throw(:abort)
    end

    def prevent_destroy
      errors.add(:base, :cannot_destroy_done_operation)
      throw(:abort)
    end

    def presence_warehouse_receiver_fio
      return unless Order::LIST_TYPE_FOR_ASSIGN_OP_RECEIVER.include?(item_type.to_s.downcase) && warehouse_receiver_fio.blank?

      errors.add(:warehouse_receiver_fio, :blank)
    end

    # Проверка, чтобы пользователь с ролью worker не назначал ФИО принявшего технику со склада, если она новая
    def check_worker_w_receiver_fio
      return unless item.status == 'non_used' && Order::LIST_TYPE_FOR_ASSIGN_OP_RECEIVER.include?(item_type.to_s.downcase) && warehouse_receiver_fio.present?

      errors.add(:base, :denied_access_for_assign_receiver_fio, item_type: item_type)
    end
  end
end
