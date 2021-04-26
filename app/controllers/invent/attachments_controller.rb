module Invent
  class AttachmentsController < ApplicationController
    def download
      attachment = Attachment.find_by(id: params[:id])

      send_file attachment.document.path, filename: attachment.document.identifier, type: attachment.document.content_type, disposition: 'attachment'
    end
  end
end
