require 'rails_helper'

module Inventory
  RSpec.describe WorkplacesController, type: :controller do
    sign_in_user

    describe 'GET #index' do
      context 'when html request' do
        it 'renders index view' do
          get :index
          expect(response).to render_template :index
        end
      end

      context 'when json request' do
        before { create_list(:full_workplace_rm_pk, 1, :add_items, items: %i[pc monitor]) }

        it 'creates an array of workplace hashes which must includes %w[division wp_type responsible location count
 status] keys' do
          get :index, format: :json
          expect(assigns(:workplaces).first.keys).to include(
            'division', 'wp_type', 'responsible', 'location', 'count', 'status'
          )
        end
      end
    end

    describe 'GET #edit' do
      let(:workplace) { create(:full_workplace_rm_pk, :add_items, items: %i[pc monitor]) }

      context 'when html request' do
        before { get :edit, params: { workplace_id: workplace } }

        it 'assigns the requested workplace to @workplace' do
          expect(assigns(:workplace)).to eq workplace
        end

        it 'renders edit page' do
          expect(response).to render_template :edit
        end
      end

      context 'when json request' do
        before { get :edit, params: { workplace_id: workplace }, format: :json }

        it 'returns workplace hash which must includes %w[workplace_id workplace_count_id workplace_type_id
 workplace_specialization_id location_site_id location_building_id inv_items_attributes]' do
          workplace = JSON.parse(response.body)
          expect(workplace.keys).to include(
            'workplace_id', 'workplace_count_id', 'workplace_type_id', 'workplace_specialization_id',
            'location_site_id', 'location_building_id', 'inv_items_attributes'
          )
          expect(workplace['inv_items_attributes'].first.keys).to include(
            'model_id', 'item_model', 'invent_num', 'inv_property_values_attributes'
          )
        end
      end
    end
  end
end
