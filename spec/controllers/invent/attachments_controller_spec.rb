require 'rails_helper'

module Invent
  RSpec.describe AttachmentsController, type: :controller do
    sign_in_user
    let(:workplace) do
      create(:workplace_pk, :add_items, items: %i[pc monitor])
    end
    let(:attachment) { create(:attachment, workplace: workplace) }

    describe 'GET #download' do
      let(:params) { { id: attachment.id } }
      let(:file_options) { { filename: attachment.document.identifier, type: attachment.document.content_type, disposition: 'attachment' } }

      it 'file is send' do
        expect(controller).to receive(:send_file).with(attachment.document.path, file_options).and_call_original

        get :download, params: params, format: :html
      end
    end
  end
end
