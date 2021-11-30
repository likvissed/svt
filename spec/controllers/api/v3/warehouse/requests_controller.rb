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
              post :new_office_equipment, params: params

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
          before { allow_any_instance_of(::Warehouse::Order).to receive(:set_consumer_dept_in) }

          it 'the status of the request is updated' do
            post :answer_from_user, params: params, as: :json

            expect(request.reload.status).to eq('on_signature')
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

        # describe 'GET #request_files' do
        #   it 'check' do
        #     get :request_files, format: :json

        #     expect(JSON.parse(response.body)).to include('full_message')
        #   end
        # end
      end
    end
  end
end
