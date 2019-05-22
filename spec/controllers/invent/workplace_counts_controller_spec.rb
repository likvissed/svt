require 'rails_helper'

module Invent
  RSpec.describe WorkplaceCountsController, type: :controller do
    sign_in_user

    describe 'GET #index ' do
      let!(:workplace_count) { create_list(:active_workplace_count, 30) }

      it 'renders index view format :html' do
        get :index, format: :html

        expect(response).to render_template :index
      end

      it 'response with success status' do
        get :index

        expect(response.status).to eq(200)
      end

      %w[division user_fullname user_phone user_time status_name pending_verification confirmed freezed].each do |i|
        it "has :#{i} attribute" do
          get :index, format: :json

          expect(JSON.parse(response.body).values[0].first.key?(i)).to be_truthy
        end
      end

      it 'count records on first page' do
        get :index, params: { start: 0, length: 25 }, format: :json

        expect(JSON.parse(response.body).values[0].count).to eq(25)
      end

      it 'count records on last page' do
        get :index, params: { start: 25, length: 25 }, format: :json

        expect(JSON.parse(response.body).values[0].count).to eq(5)
      end
    end
  end
end
