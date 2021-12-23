require 'rails_helper'

module Api
  module V3
    module Warehouse
      RSpec.describe RequestsController, type: :controller do
        describe 'POST #new_office_equipment' do
          let(:file) do
            Rack::Test::UploadedFile.new(File.open(Rails.root.join('spec/files/new_pc_config.txt')))
          end
          let(:emp_user) { build(:emp_***REMOVED***) }
          let(:count_request_items) { JSON.parse(params[:parameters])['table_data'].count }
          before { allow_any_instance_of(RequestsController).to receive(:find_user).and_return([emp_user]) }

          context 'when params is valid' do
            let(:params) do
              {
                id: 121,
                description: 'Выдача вычислительной техники в подразделение согласно перечня ПО',
                created_at: '2021-11-12 10:42:15 +0700',
                parameters: '{
                  "common": {
                    "tn": ***REMOVED***,
                    "fio": "***REMOVED***",
                    "***REMOVED***_id": 1000
                  },
                  "table_data": [
                    {
                      "type": "pc",
                      "reason": "Старый тормозит",
                      "invent_num": "765123",
                      "description": "Офисный ПК: Intel Core i3, RAM 4Gb, HDD 500Gb,VA встроеный, Монитор  22\", клавиатура, мышь, ОС, Офис"
                    },
                    {
                      "type": "pc",
                      "reason": "Старый тормозит 2",
                      "invent_num": "765123 2"
                    }
                  ]
                }',
                files: [file]
              }
            end

            it 'response contains :id key' do
              post :new_office_equipment, params: params

              expect(JSON.parse(response.body)).to include('id')
            end

            it 'increase count of warehouse_requests' do
              expect { post :new_office_equipment, params: params }.to change(::Warehouse::Request, :count).by(1)
            end

            it 'increase count of warehouse_request_items' do
              expect { post :new_office_equipment, params: params }.to change(::Warehouse::RequestItem, :count).by(count_request_items)
            end

            it 'increase count of warehouse_attachment_requests' do
              expect { post :new_office_equipment, params: params }.to change(::Warehouse::AttachmentRequest, :count).by(1)
            end
          end

          context 'when param :number_***REMOVED*** is blank' do
            let(:params) do
              {
                id: 121,
                description: 'Выдача вычислительной техники в подразделение согласно перечня ПО',
                created_at: '2021-11-12 10:42:15 +0700',
                parameters: '{
                  "common": {
                    "tn": ***REMOVED***,
                    "fio": "***REMOVED***"
                  },
                  "table_data": [
                    {
                      "type": "pc",
                      "reason": "Старый тормозит",
                      "invent_num": "765123"
                    }
                  ]
                }'
              }
            end

            it 'adds error messages' do
              post :new_office_equipment, params: params, format: :json

              expect(JSON.parse(response.body)).to include('full_message')
            end
          end
        end

        describe 'POST #answer_from_user' do
          let(:request) { create(:request_category_one) }
          let(:params) do
            {
              id: request.request_id,
              answer: true,
              comment: nil
            }
          end
          let!(:order) do
            order = build(:order, operation: :out, request: request)
            order.save(validate: false)
            order
          end
          before { allow_any_instance_of(::Warehouse::Order).to receive(:set_consumer_dept_in) }

          it 'the status of the request is updated' do
            post :answer_from_user, params: params, as: :json

            expect(request.reload.status).to eq('in_work')
          end

          context 'when user disagree' do
            let!(:order) { create(:order, request: request) }
            before do
              params[:answer] = false
              allow(Orbita).to receive(:add_event)
            end

            it 'update status and closing the request' do
              post :answer_from_user, params: params

              expect(request.reload.status).to eq('reject')
            end

            it 'destroys order' do
              expect { post :answer_from_user, params: params }.to change(::Warehouse::Order, :count).by(-1)
            end
          end

          context 'when request_is is empty' do
            before { params[:id] = 122_122 }

            it 'raises a RuntimeError error' do
              expect { post :answer_from_user, params: params }.to raise_error(RuntimeError, "Заявка не найдена: #{params[:id]}")
            end
          end
        end

        describe 'POST #answer_from_owner' do
          let(:request) { create(:request_category_one) }
          let(:file) do
            Rack::Test::UploadedFile.new(File.open(Rails.root.join('spec/files/new_pc_config.txt')))
          end
          let(:params) do
            {
              id: request.request_id,
              process_id: request.ssd_id,
              status: 'SIGNED',
              files: file
            }
          end
          before { allow(Orbita).to receive(:add_event) }

          it 'the status of the request is updated' do
            post :answer_from_owner, params: params

            expect(request.reload.status).to eq('create_order')
          end

          it 'increase count of warehouse_attachment_requests' do
            expect { post :answer_from_owner, params: params }.to change(::Warehouse::AttachmentRequest, :count).by(1)
          end

          context 'when owner disagree' do
            before { params[:status] = 'UNSIGNED' }

            it 'update status and closing the request' do
              post :answer_from_owner, params: params

              expect(request.reload.status).to eq('reject')
            end
          end
        end

        describe 'GET #request_files' do
          let(:attachment_request) { create(:attachment_request) }
          let(:request) { create(:request_category_one, attachments: [attachment_request]) }
          let(:url) { "https://#{ENV['APP_HOSTNAME']}.***REMOVED***.ru/api/v3/warehouse/requests/download_attachment_request/#{attachment_request.id}" }

          %w[url format description].each do |i|
            it "has :#{i} attribute" do
              get :request_files, params: { process_id: request.ssd_id }, format: :json

              expect(JSON.parse(response.body).first.key?(i)).to be_truthy
            end
          end

          it 'attribute :url is present' do
            get :request_files, params: { process_id: request.ssd_id }, format: :json

            expect(JSON.parse(response.body).first['url']).to eq(url)
          end

          it 'attribute :description is present' do
            get :request_files, params: { process_id: request.ssd_id }, format: :json

            expect(JSON.parse(response.body).first['description']).to eq('Список ПО или др.вложенные документы')
          end

          it 'attribute :format is present and correct' do
            get :request_files, params: { process_id: request.ssd_id }, format: :json

            expect(JSON.parse(response.body).first['format']).to eq(attachment_request.document.content_type)
          end
        end

        describe 'GET #download_attachment_request' do
          let(:attachment_request) { create(:attachment_request) }
          let(:request) { create(:request_category_one, attachments: [attachment_request]) }
          let(:file_options) { { filename: attachment_request.document.identifier, type: attachment_request.document.content_type, disposition: 'inline' } }

          it 'file is send' do
            @request.env['HTTP_SSD_FILE_TOKEN'] = request.ssd_id

            expect(controller).to receive(:send_file).with(attachment_request.document.path, file_options).and_call_original

            get :download_attachment_request, params: { id: attachment_request.id }, format: :html
          end
        end
      end
    end
  end
end
