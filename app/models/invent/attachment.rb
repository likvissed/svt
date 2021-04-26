module Invent
  class Attachment < BaseInvent
    self.primary_key = :id
    self.table_name = "#{table_name_prefix}attachments"

    belongs_to :workplace, foreign_key: 'workplace_id', inverse_of: :attachments

    mount_uploader :document, DocumentUploader
  end
end
