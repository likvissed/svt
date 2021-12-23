module Warehouse
  class AttachmentRequestsController < Warehouse::ApplicationController
    def download
      attachment = AttachmentRequest.find_by(id: params[:id])

      send_file attachment.document.path, filename: attachment.document.identifier, type: attachment.document.content_type, disposition: 'inline'
    end
  end
end
