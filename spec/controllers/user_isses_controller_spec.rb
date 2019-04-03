require 'rails_helper'

RSpec.describe UserIssesController, type: :controller do
  sign_in_user

  describe 'GET #users_from_division' do
    let(:user) { create(:***REMOVED***_user) }
    let!(:workplace_count) { create(:active_workplace_count, division: ***REMOVED***, users: [user]) }

    it 'creates instance of the WorkplaceCounts::Index class' do
      get :users_from_division, params: { division: workplace_count.division }, format: :json

      expect(response.body).to eq UserIss.select(:id_tn, :fio).order(:fio).where(dept: workplace_count.division).to_json
    end
  end

  describe 'GET #items' do
    let(:user_iss_id_tn) { @user.id_tn }
    let!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor], id_tn: user_iss_id_tn) }
    let!(:another_workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }

    it 'loads all items for specified user' do
      get :items, params: { user_iss_id: user_iss_id_tn }, format: :json

      expect(response.body).to have_json_size(workplace.items.size)
    end

    it 'does not load items from another workplaces' do
      get :items, params: { user_iss_id: user_iss_id_tn }, format: :json

      parse_json(response.body).each do |item|
        expect(item['workplace_id']).not_to eq another_workplace.workplace_id
      end
    end

    it 'has :short_item_model attribute' do
      get :items, params: { user_iss_id: user_iss_id_tn }, format: :json

      expect(response.body).to have_json_path('0/short_item_model')
    end
  end
end
