require 'rails_helper'

RSpec.describe StatisticsController, type: :controller do
  sign_in_user

  describe 'GET #ups_batteries' do
    it 'creates instance of the Users::Index' do
      get :show, format: :json
      expect(assigns(:stat)).to be_instance_of Statistics
    end

    it 'calls :run method' do
      expect_any_instance_of(Statistics).to receive(:run)
      get :show, format: :json
    end
  end
end
