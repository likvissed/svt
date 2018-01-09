module Warehouse
  class Operation < BaseWarehouse
    self.primary_key = :warehouse_operation_id
    self.table_name = "#{table_name_prefix}operations"

    belongs_to :item, foreign_key: 'warehouse_item_id', optional: true
    belongs_to :location, foreign_key: 'warehouse_location_id', optional: true
    belongs_to :stockman, class_name: 'UserIss', foreign_key: 'stockman_id_tn', optional: true
    belongs_to :operationable, polymorphic: true

    validates :item_type, :item_model, :shift, :status, presence: true
    validates :stockman_fio, :date, presence: true, if: -> { status == 'done' }

    after_initialize :set_initial_status

    attr_accessor :invent_item_id

    enum status: { processing: 1, done: 2 }

    protected

    def set_initial_status
      self.status = :processing
    end
  end
end
