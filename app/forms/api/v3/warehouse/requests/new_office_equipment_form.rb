module Api
  module V3
    module Warehouse
      module Requests
        class NewOfficeEquipmentForm < Reform::Form
          property :category, default: 'office_equipment'
          property :status, default: 'new'

          property :number_***REMOVED***, validates: { presence: true }

          property :user_tn, validates: { presence: true }
          property :user_fio, validates: { presence: true }
          property :user_dept
          property :user_phone

          collection :request_items, populate_if_empty: ::Warehouse::RequestItem do
            property :name, presence: true
            property :reason, validates: { presence: true }
            property :count
          end

          collection :attachments, populate_if_empty: ::Warehouse::AttachmentRequest do
            property :document, validates: { presence: true }
          end

          validate :request_items?

          def request_items?
            errors.add(:base, :warehouse_request_items_is_blank) unless request_items.size.positive?
          end
        end
      end
    end
  end
end
