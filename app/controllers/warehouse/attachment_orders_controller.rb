module Warehouse
  class AttachmentOrdersController < Warehouse::ApplicationController
    def create
      attachment = AttachmentOrder.new(document: params[:attachment_order], order_id: params[:order_id])

      if attachment.save
        render json: { full_message: I18n.t('controllers.warehouse/attachment_order.created', order_id: params[:order_id]) }
      else
        render json: { full_message: attachment.errors.full_messages.join('. ') }, status: 422
      end
    end

    def download
      attachment = AttachmentOrder.find_by(id: params[:id])

      raise "Файл для ордера #{params[:id]} не существует" if attachment.blank?

      send_file attachment.document.path, filename: attachment.document.identifier, type: attachment.document.content_type, disposition: 'attachment'
    end
  end
end
