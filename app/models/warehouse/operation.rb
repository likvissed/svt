module Warehouse
  class Operation < BaseWarehouse
    self.primary_key = :warehouse_operation_id
    self.table_name = "#{table_name_prefix}operations"

    belongs_to :item, foreign_key: 'warehouse_item_id', optional: true
    belongs_to :location, foreign_key: 'warehouse_location_id', optional: true
    belongs_to :stockman, class_name: 'UserIss', foreign_key: 'stockman_id_tn', optional: true
    belongs_to :operationable, polymorphic: true

    validates :item_type, :item_model, :shift, :status, presence: true
    validates :stockman_fio, :date, presence: true, if: -> { done? }
    validate :uniq_item_by_processing_operation, if: -> { item.try(:used) && warehouse_item_id_changed? }

    after_initialize :set_initial_status, if: -> { new_record? }
    before_validation :set_date, if: -> { done? && status_changed? }
    before_update :prevent_update

    attr_accessor :invent_item_id

    enum status: { processing: 1, done: 2 }

    accepts_nested_attributes_for :item, allow_destroy: false

    def destroy
      raise I18n.t('activerecord.errors.models.warehouse/operation.attributes.base.cannot_destroy_done') if done?

      super
    end

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

    protected

    def set_initial_status
      self.status ||= :processing
    end

    def uniq_item_by_processing_operation
      op = item.operations.find(&:processing?)
      return unless op

      errors.add(
        :base,
        :operation_already_exists,
        type: item.item_type,
        invent_num: item.inv_item.invent_num,
        order_id: op.operationable.warehouse_order_id
      )
    end

    def set_date
      self.date = Time.zone.now
    end

    def prevent_update
      return true unless done? && !status_changed? || processing? && status_was == 'done'

      errors.add(:base, :cannot_update_done_operation)
      throw(:abort)
    end
  end
end
