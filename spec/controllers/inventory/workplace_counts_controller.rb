require 'rails_helper'

module Inventory
  RSpec.describe WorkplaceCountsController, type: :controller do
    sign_in_user

    describe 'GET #index' do
      context 'with json request' do
        it 'creates instance of the WorkplaceCounts::Index class' do
          get :index, format: :json
          expect(assigns(:index)).to be_instance_of WorkplaceCounts::Index
        end

        it 'returns to client @data variable' do
          expect_any_instance_of(WorkplaceCounts::Index).to receive(:data)
          get :index, format: :json
        end
      end
    end
  end
end