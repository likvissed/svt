module Warehouse
  class AttachmentRequest < BaseWarehouse
    self.primary_key = :id
    self.table_name = "#{table_name_prefix}attachment_requests"

    belongs_to :request, foreign_key: 'request_id', inverse_of: :attachments

    mount_uploader :document, DocumentUploader
  end
end
