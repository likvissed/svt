require 'rails_helper'

module Invent
  RSpec.describe SignsController, type: :controller do
    sign_in_user

    describe 'GET #load_signs' do
      it 'response value with signs' do
        get :load_signs

        expect(response.status).to eq(200)
      end
    end
  end
end
