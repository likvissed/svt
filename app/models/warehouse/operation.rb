module Warehouse
  class Operation < BaseWarehouse
    self.table_name = "#{table_name_prefix}operations"

    has_many :inv_item_to_operations, dependent: :destroy
    has_many :inv_items, through: :inv_item_to_operations, class_name: 'Invent::Item'

    belongs_to :item, optional: true
    belongs_to :location, optional: true
    belongs_to :stockman, class_name: 'UserIss', foreign_key: 'stockman_id_tn', optional: true
    belongs_to :operationable, polymorphic: true

    validates :item_type, :item_model, :shift, :status, presence: true
    validates :stockman_fio, :date, presence: true, if: -> { done? }
    validate :uniq_item_by_processing_operation, if: -> { item.try(:used) && item_id_changed? }

    after_initialize :set_initial_status, if: -> { new_record? }
    after_initialize :set_initial_shift, if: -> { new_record? }
    before_validation :set_date, if: -> { done? && status_changed? }
    before_update :prevent_change_status
    before_update :prevent_update
    before_destroy :prevent_destroy, if: -> { done? }

    accepts_nested_attributes_for :inv_items, allow_destroy: false

    enum status: { processing: 1, done: 2 }

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
      date.strftime("%d-%m-%Y") if date
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
      return true unless done? && !status_changed?

      errors.add(:base, :cannot_update_done_operation)
      throw(:abort)
    end

    def prevent_destroy
      errors.add(:base, :cannot_destroy_done_operation)
      throw(:abort)
    end
  end
end
