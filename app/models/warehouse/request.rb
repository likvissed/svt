module Warehouse
  class Request < BaseWarehouse
    self.primary_key = :request_id
    self.table_name = "#{table_name_prefix}requests"

    has_many :attachments, foreign_key: 'request_id', class_name: 'AttachmentRequest', dependent: :destroy, inverse_of: :request
    has_many :request_items, foreign_key: 'request_id', dependent: :destroy, inverse_of: :request

    has_one :order, foreign_key: 'request_id', inverse_of: :request, dependent: :nullify

    enum category: { office_equipment: 1, printing: 2, expendable_materials: 3 }, _prefix: true
    enum status: { new: 1, analysis: 2, check: 3, waiting_confirmation_for_user: 4, on_signature: 5, in_work: 6, completed: 7, closed: 8 }, _prefix: true
  end
end
