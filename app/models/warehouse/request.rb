module Warehouse
  class Request < BaseWarehouse
    self.primary_key = :request_id
    self.table_name = "#{table_name_prefix}requests"

    has_many :attachments, foreign_key: 'request_id', class_name: 'AttachmentRequest', dependent: :destroy, inverse_of: :request
    has_many :request_items, foreign_key: 'request_id', dependent: :destroy, inverse_of: :request

    belongs_to :order, foreign_key: 'order_id', optional: true, inverse_of: :request

    enum category: { office_equipment: 1, printing: 2, expendable_materials: 3 }, _prefix: true
    enum status: { new: 1, analysis: 2, check: 3, on_signature: 4, waiting_confirmation_for_user: 5, in_work: 6, closed: 7 }, _prefix: true
  end
end
