module Warehouse
  class Request < BaseWarehouse
    self.primary_key = :request_id
    self.table_name = "#{table_name_prefix}requests"

    # Список фильтров по умолчанию для фильтра "Статусы"
    DEFAULT_STATUS_FILTER = %w[new analysis check waiting_confirmation_for_user on_signature in_work].freeze

    has_many :attachments, foreign_key: 'request_id', class_name: 'AttachmentRequest', dependent: :destroy, inverse_of: :request
    has_many :request_items, foreign_key: 'request_id', dependent: :destroy, inverse_of: :request

    has_one :order, foreign_key: 'request_id', inverse_of: :request, dependent: :nullify

    scope :request_id, ->(request_id) { where(request_id: request_id) }
    scope :order_id, ->(order_id) { joins(:order).where(warehouse_orders: { id: order_id }) }
    scope :category, ->(category) { where(category: category) }
    scope :for_statuses, ->(status_arr) do
      result = []
      values = status_arr.map do |el|
        result << "#{table_name}.status = ?"
        el['id']
      end

      where(result.join(' OR '), *values)
    end

    enum category: { office_equipment: 1, printing: 2, expendable_materials: 3 }, _prefix: true
    enum status: { new: 1, analysis: 2, check: 3, waiting_confirmation_for_user: 4, on_signature: 5, in_work: 6, ready: 7, completed: 8, closed: 9 }, _prefix: true
  end
end
