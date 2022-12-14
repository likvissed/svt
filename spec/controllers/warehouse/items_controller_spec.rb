require 'rails_helper'

module Warehouse
  RSpec.describe ItemsController, type: :controller do
    sign_in_user
    let(:params) { { start: 0, length: 25 } }

    describe 'GET #index' do
      it 'creates instance of the Items::Index' do
        get :index, params: params, format: :json
        expect(assigns(:index)).to be_instance_of Items::Index
      end

      it 'calls :run method' do
        expect_any_instance_of(Items::Index).to receive(:run)
        get :index, params: params, format: :json
      end
    end

    describe 'GET #edit' do
      let(:item) { create(:new_item) }

      it 'calls :run method' do
        expect_any_instance_of(Items::Edit).to receive(:run)

        get :edit, params: { id: item.id }, format: :json
      end

      context 'when method :run returns true' do
        before { allow_any_instance_of(Items::Edit).to receive(:run).and_return(true) }

        it 'response with success status' do
          get :edit, params: { id: item.id }, format: :json

          expect(response.status).to eq(200)
        end
      end

      context 'when method :run returns false' do
        before { allow_any_instance_of(Items::Edit).to receive(:run).and_return(false) }

        it 'response with error status' do
          get :edit, params: { id: item.id }, format: :json

          expect(response.status).to eq(422)
        end
      end
    end

    describe 'PUT #update' do
      let(:item) { create(:item_with_property_values) }
      let(:params) { { id: item.id, item: item.as_json } }

      it 'calls :run method' do
        expect_any_instance_of(Items::Update).to receive(:run)

        put :update, params: params
      end

      context 'when method :run returns true' do
        before { allow_any_instance_of(Items::Update).to receive(:run).and_return(true) }

        it 'response with success status' do
          put :update, params: params

          expect(response.status).to eq(200)
        end

        it 'response with full_message' do
          put :update, params: params

          expect(JSON.parse(response.body)['full_message']).to eq('???????????????? ?????????????? ??????????????????')
        end
      end

      context 'when method :run returns false' do
        before { allow_any_instance_of(Items::Update).to receive(:run).and_return(false) }

        it 'response with error status' do
          put :update, params: params

          expect(response.status).to eq(422)
        end
      end
    end

    describe 'GET #split' do
      let(:item) { create(:new_item, count: 4, invent_num_end: 114) }
      let(:location) { create(:location) }
      let(:items_attributes) do
        it = Hash[item.as_json.map { |key, value| [key.to_sym, value.to_i] }]

        it['location'] = location.as_json
        it['count_for_invent_num'] = 2

        items = [it, it]
        items
      end
      let(:params) { { id: item.id, items: items_attributes } }

      context 'when method :run returns true' do
        before { allow_any_instance_of(Items::Split).to receive(:run).and_return(true) }

        it 'response with full_message' do
          put :split, params: params

          expect(JSON.parse(response.body)['full_message']).to eq('???????????????????? ?????????????? ??????????????????')
        end
      end

      context 'when method :run returns false' do
        before { allow_any_instance_of(Items::Split).to receive(:run).and_return(false) }

        it 'response with full_message' do
          put :split, params: params

          expect(response.status).to eq(422)
        end
      end
    end
  end
end
