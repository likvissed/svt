require 'rails_helper'

module Api
  module V2
    module Invent
      RSpec.describe ItemsController, type: :controller do
        describe 'GET #search_barcode' do
          let(:item) { create(:item, :with_property_values, type_name: :monitor, workplace_id: 123, status: :in_workplace) }
          let(:result_data) do
            item.as_json(
              include: [
                :barcode_item,
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

          before do
            get :search_barcode, params: { barcode: item.barcode_item.id }, format: :json
          end

          it 'loads item with invent_num' do
            expect(JSON.parse(response.body).first).to eq result_data
          end

          context 'when status item not in_workplace' do
            let!(:item) { create(:item, :with_property_values, type_name: :monitor, workplace_id: 123, status: :waiting_take) }

            it 'returns is blank result' do
              expect(response.body).to eq '{}'
            end
          end
        end
      end
    end
  end
end
