require 'rails_helper'

module Warehouse
  RSpec.describe AttachmentOrdersController, type: :controller do
    sign_in_user
    let(:file) { Rack::Test::UploadedFile.new(Rails.root.join('spec/files/new_pc_config.txt'), 'text/plain') }

    describe 'POST #create' do
      let(:params) { { attachment_order: file, order_id: order.id } }
      let!(:order) do
        order = build(:order)
        order.operation = :out
        order.status = :done
        order.save(validate: false)
        order
      end

      context 'when order is valid' do
        it 'response with success status' do
          post :create, params: params

          expect(response.status).to eq(200)
        end
      end

      context 'when order is not valid' do
        context 'and when order not done' do
          let!(:order) do
            order = build(:order)
            order.save(validate: false)
            order
          end

          it 'response with error status' do
            post :create, params: params

            expect(response.status).to eq(422)
          end

          it 'adds error include :warehouse_order_is_not_out_or_done' do
            post :create, params: params

            expect(JSON.parse(response.body)['full_message']).to eq('Добавление документа допустимо только для исполненного расходного ордера')
          end
        end

        context 'and when attathment is present for order' do
          let(:att_order) { create(:attachment_order, order: order) }
          before { order.attachment = att_order }

          it 'adds error include :warehouse_order_is_present_attachment' do
            post :create, params: params

            expect(JSON.parse(response.body)['full_message']).to eq("Ордер №#{order.id} уже имеет вложенный документ")
          end
        end

        context 'and when order was destroy' do
          let(:not_valid_order_id) { 999_999 }
          let(:params) { { attachment_order: file, order_id: not_valid_order_id } }

          it 'adds error include :warehouse_order_is_not_present' do
            post :create, params: params

            expect(JSON.parse(response.body)['full_message']).to eq("Ордер №#{not_valid_order_id} не существует")
          end
        end
      end
    end

    describe 'GET #download' do
      let(:order) { create(:order) }
      let(:attachment_order) do
        att = build(:attachment_order, order: order)
        att.save(validate: false)
        att
      end
      let(:params) { { id: attachment_order.id } }
      let(:file_options) { { filename: attachment_order.document.identifier, type: attachment_order.document.content_type, disposition: 'attachment' } }

      it 'file is send' do
        expect(controller).to receive(:send_file).with(attachment_order.document.path, file_options).and_call_original

        get :download, params: params, format: :html
      end
    end
  end
end
