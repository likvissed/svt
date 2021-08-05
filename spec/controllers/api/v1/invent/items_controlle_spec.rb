require 'rails_helper'

module Api
  module V1
    module Invent
      RSpec.describe ItemsController, type: :controller do
        describe 'GET #index' do
          context 'when sent parametr invent_num' do
            let(:item) { create(:item, :with_property_values, type_name: :monitor, workplace_id: 123, status: :in_workplace) }
            let(:result_data) do
              item.as_json(
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
            end

            before { get :index, params: { invent_num: item.invent_num }, format: :json }

            it 'loads item with invent_num' do
              expect(JSON.parse(response.body).first).to eq result_data
            end

            context 'when status item not in_workplace' do
              let!(:item) { create(:item, :with_property_values, type_name: :monitor, workplace_id: 123, status: :waiting_take) }

              it 'returns is blank result' do
                expect(response.body).to eq '[]'
              end
            end

            context 'when an empty parameter is sent invent_num' do
              it 'returns is blank result' do
                get :index, params: { invent_num: '' }, format: :json

                expect(response.body).to eq '[]'
              end
            end
          end

          context 'when sent parametr tn' do
            before { allow(UsersReference).to receive(:info_users).and_return([build(:emp_***REMOVED***)]) }
            let(:user) { create(:***REMOVED***_user) }

            context 'and when the user is not responsible in the division' do
              let(:inv_item) { create(:item, :with_property_values, type_name: :pc, status: :in_workplace) }
              let!(:workplace) do
                w = build(:workplace_pk, items: [inv_item])
                w.save(validate: false)
                w
              end
              before { get :index, params: { tn: user.tn }, format: :json }

              it 'returns is blank result' do
                expect(response.body).to eq '[]'
              end
            end

            context 'and when the user is responsible in his division' do
              let!(:workplace_count) { create(:active_workplace_count, users: [user]) }
              let(:inv_item_one) { create(:item, :with_property_values, type_name: :pc, status: :waiting_take) }
              let(:inv_item_two) { create(:item, :with_property_values, type_name: :monitor, status: :in_workplace) }
              let(:inv_item_three) { create(:item, :with_property_values, type_name: :monitor, status: :in_workplace) }
              let!(:workplace) do
                w = build(:workplace_pk, items: [inv_item_one, inv_item_two, inv_item_three], workplace_count: workplace_count)
                w.save(validate: false)
                w
              end
              let(:result_data) do
                items = workplace.items.find_by(status: :in_workplace).as_json(
                  include: [
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
                )

                items.merge!('fio_user_iss': 'Ответственный не найден')
                items.transform_keys(&:to_s)
              end

              before { get :index, params: { tn: user.tn }, format: :json }

              it 'loads item with the user`s tn' do
                expect(JSON.parse(response.body).first).to eq result_data
              end

              it 'loads items with status is in_workplace' do
                JSON.parse(response.body).each do |result_item|
                  expect(result_item['status']).to eq 'in_workplace'
                end
              end

              it 'count loads items with status is in_workplace' do
                expect(JSON.parse(response.body).count).to eq workplace.items.where(status: 'in_workplace').count
              end
            end

            context 'when tn user not present' do
              it 'returns is blank result' do
                get :index, params: { tn: 110_011 }, format: :json

                expect(response.body).to eq '[]'
              end
            end

            context 'when an empty parameter is sent tn' do
              it 'returns is blank result' do
                get :index, params: { tn: user.tn }, format: :json

                expect(response.body).to eq '[]'
              end
            end
          end
        end
      end
    end
  end
end
