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
end
