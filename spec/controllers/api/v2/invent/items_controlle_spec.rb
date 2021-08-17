require 'rails_helper'

module Api
  module V2
    module Invent
      RSpec.describe ItemsController, type: :controller do
        describe 'GET #barcode' do
          let(:item) { create(:item, :with_property_values, type_name: :monitor, workplace_id: 123, status: :in_workplace) }
          let(:barcode) { item.barcode_item }
          let(:result_data) do
            barcode_item = barcode.as_json(include: {
                                             codeable: {
                                               include: [
                                                 :barcode_item,
                                                 {
                                                   type: { except: %i[create_time modify_time] }
                                                 },
                                                 {
                                                   workplace: {
                                                     except: %i[create_time]
                                                   }
                                                 }
                                               ],
                                               except: %i[create_time modify_time],
                                               methods: :short_item_model
                                             }
                                           })
            barcode_item['codeable']
          end

          before { get :barcode, params: { barcode: item.barcode_item.id }, format: :json }

          it 'loads item with invent_num' do
            expect(JSON.parse(response.body)).to eq result_data
          end

          context 'when status item not in_workplace' do
            let!(:item) { create(:item, :with_property_values, type_name: :monitor, workplace_id: 123, status: :waiting_take) }

            it 'returns is blank result' do
              expect(response.body).to eq '{}'
            end
          end
        end

        describe 'GET #search_items' do
          before do
            allow(UsersReference).to receive(:info_users).and_return([build(:emp_***REMOVED***)])
            allow_any_instance_of(User).to receive(:presence_user_in_users_reference).and_return([employee])
          end
          let(:employee) { build(:emp_***REMOVED***) }

          let!(:item) { create(:item, :with_property_values, type_name: :monitor, status: :in_workplace) }
          let!(:workplace) do
            w = build(:workplace_pk, items: [item], id_tn: employee['id'])
            w.save(validate: false)
            w
          end
          let(:result_data) do
            data = item.as_json(
              include: [
                :barcode_item,
                {
                  workplace: {
                    except: %i[create_time]
                  }
                },
                {
                  type: {
                    except: %i[create_time modify_time]
                  }
                }
              ],
              except: %i[create_time modify_time],
              methods: :short_item_model
            )
            data['workplace']['user_fio'] = employee['fullName']
            data
          end

          before { get :search_items, params: params, format: :json }

          context 'when params is valid' do
            context 'and when the parameter invent_num is received' do
              let(:params) { { invent_num: item.invent_num } }

              it 'loads item with invent_num' do
                expect(JSON.parse(response.body).first).to eq result_data
              end

              it 'response with error status' do
                expect(response.status).to eq(200)
              end
            end

            context 'and when the parameter dept is received' do
              let(:params) { { dept: employee['departmentForAccounting'] } }

              it 'loads item with dept' do
                expect(JSON.parse(response.body).first).to eq result_data
              end
            end

            context 'and when the parameter fio is received' do
              let(:params) { { fio: employee['fullName'] } }

              it 'loads item with fio' do
                expect(JSON.parse(response.body).first).to eq result_data
              end
            end

            context 'and when the parameter barcode is received' do
              let(:params) { { barcode: item.barcode_item.id } }
              before { allow(response).to receive(:body).and_return(result_data) }

              it 'loads item with barcode' do
                expect(response.body).to eq result_data
              end
            end

            context 'and when data the parameters not present' do
              let(:params) { { barcode: 123, fio: 'fio', dept: ***REMOVED***, invent_num: 999_999 } }

              it 'returns is blank result' do
                expect(response.body).to eq '[]'
              end
            end
          end

          context 'when params is invalid' do
            context 'and when the parameter not present' do
              let(:params) { { not_present: '321' } }

              it 'returns is blank result' do
                expect(response.body).to eq '[]'
              end
            end

            context 'and when dept not present' do
              let(:invalid_dept) { 111_111 }
              let(:params) { { dept: invalid_dept } }

              it 'returns is blank result' do
                expect(response.body).to eq '[]'
              end

              it 'response with status 200' do
                expect(response.status).to eq(200)
              end
            end

            context 'and when barcode not only number' do
              let(:invalid_barcode) { '123Bs@' }
              let(:params) { { barcode: invalid_barcode } }

              it 'returns is blank result' do
                expect(response.body).to eq '[]'
              end

              it 'response with status 200' do
                expect(response.status).to eq(200)
              end
            end
          end
        end
      end
    end
  end
end
