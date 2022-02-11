require 'rails_helper'

module Warehouse
  RSpec.describe RequestsController, type: :controller do
    sign_in_user
    before { allow(Orbita).to receive(:add_event) }

    describe 'GET #index' do
      let!(:requests) { create_list(:request_category_one, 30) }

      %w[user_tn user_id_tn user_fio user_dept user_phone number_***REMOVED*** number_***REMOVED*** executor_fio executor_tn comment label_status category_translate request_items].each do |i|
        it "has :#{i} attribute" do
          get :index, format: :json

          expect(JSON.parse(response.body)['data'].first.key?(i)).to be_truthy
        end
      end

      it 'count records on first page' do
        get :index, params: { start: 0, length: 25 }, format: :json

        expect(JSON.parse(response.body)['data'].count).to eq(25)
      end

      it 'count records on last page' do
        get :index, params: { start: 25, length: 25 }, format: :json

        expect(JSON.parse(response.body)['data'].count).to eq(5)
      end
    end

    describe 'GET #edit' do
      let(:request) { create(:request_category_one) }
      let(:params) { { id: request.request_id } }

      let!(:user_worker) { create(:shatunova_user) }

      %w[request_items attachments status_translated].each do |i|
        it "has :#{i} attribute" do
          get :edit, params: params, format: :json

          expect(JSON.parse(response.body)['request'].key?(i)).to be_truthy
        end
      end

      context 'when request_id not present' do
        let(:params) { { id: 901_901 } }

        it 'raises RecordNotFound error' do
          expect { get :edit, params: params, format: :json }.to raise_exception(ActiveRecord::RecordNotFound)
        end
      end
    end

    describe 'PUT #send_for_analysis' do
      let(:request) { create(:request_category_one) }
      let(:params) { { id: request.request_id, request: attributes_for(:request_category_one) } }

      it 'status request updates as :analysis' do
        put :send_for_analysis, params: params

        expect(request.reload.status).to eq('analysis')
      end

      it 'adds success message' do
        put :send_for_analysis, params: params

        expect(JSON.parse(response.body)['full_message']).to eq('Статус заявки успешно изменен')
      end
    end

    describe 'PUT #assign_new_executor' do
      let(:request) { create(:request_category_one) }
      let(:user_worker) { attributes_for(:shatunova_user) }
      let(:params) { { id: request.request_id, executor: user_worker } }

      it 'updates executor_fio and executor_tn attributes' do
        put :assign_new_executor, params: params

        expect(request.reload.executor_fio).to eq(user_worker[:fullname])
        expect(request.reload.executor_tn).to eq(user_worker[:tn])
      end

      it 'adds success message' do
        put :assign_new_executor, params: params

        expect(JSON.parse(response.body)['full_message']).to eq('Исполнитель успешно переназначен')
      end
    end

    describe 'GET #close' do
      let(:request) { create(:request_category_one) }
      let!(:order) do
        ord = build(:order, request: request, operation: :out)
        ord.save(validate: false)
        ord
      end
      let(:params) { { id: request.request_id } }

      it 'status request updates as :reject' do
        get :close, params: params

        expect(request.reload.status).to eq('reject')
      end

      it 'destroys order' do
        expect { get :close, params: params }.to change(Order, :count).by(-1)
      end

      it 'adds success message' do
        get :close, params: params

        expect(JSON.parse(response.body)['full_message']).to eq("Заявка №#{request.request_id} закрыта")
      end
    end

    describe 'PUT #confirm_request_and_order' do
      let(:request) { create(:request_category_one, status: :create_order) }

      let(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
      let(:order) { create(:order, operation: :out, inv_workplace: workplace, request: request) }
      let(:params) { { id: request.request_id, order_id: order.id } }
      before { allow_any_instance_of(Order).to receive(:present_user_iss) }

      it 'status request updates as :waiting_confirmation_for_user' do
        put :confirm_request_and_order, params: params

        expect(request.reload.status).to eq('waiting_confirmation_for_user')
      end

      it 'set_validator for order' do
        put :confirm_request_and_order, params: params

        order.reload
        expect(order.validator_id_tn).to eq @user.id_tn
        expect(order.validator_fio).to eq @user.fullname
      end

      it 'adds success message' do
        put :confirm_request_and_order, params: params

        expect(JSON.parse(response.body)['full_message']).to eq("Заявка №#{request.request_id} и ордер №#{request.order.id} утверждены")
      end
    end

    describe 'PUT #ready' do
      let(:request) { create(:request_category_one) }
      let(:params) { { id: request.request_id } }

      it 'status request updates as :ready' do
        put :ready, params: params

        expect(request.reload.status).to eq('ready')
      end
    end

    describe 'PUT #send_to_owner' do
      let(:request) { create(:request_category_one) }
      let!(:order) do
        ord = build(:order, operation: :out, request: request)
        ord.save(validate: false)
        ord
      end
      let(:owner) { attributes_for(:***REMOVED***_user) }
      let(:request_params) { attributes_for(:request_category_one) }
      let(:params) { { id: request.request_id, owner: owner, request: request_params } }
      before { allow_any_instance_of(Requests::SendToOwner).to receive(:run).and_return(true) }

      it 'adds success message' do
        put :send_to_owner, params: params

        expect(JSON.parse(response.body)['full_message']).to eq("Заявка №#{params[:id]} отправлена на подпись в ССД")
      end
    end

    describe 'PUT #update' do
      let(:request) { create(:request_category_one) }
      let(:new_comment) { 'text' }
      let(:params) { { id: request.request_id, request: attributes_for(:request_category_one, comment: new_comment) } }

      it 'adds success message' do
        put :update, params: params

        expect(JSON.parse(response.body)['full_message']).to eq('Комментарий обновлен')
      end

      context 'when status is :completed for request' do
        before { params[:request][:status] = 'completed' }

        it 'response with error status' do
          put :update, params: params

          expect(response.status).to eq(422)
        end
      end
    end

    describe 'PUT #expected_is_stock' do
      let(:request) { create(:request_category_one) }
      let(:params) { { id: request.request_id, flag: true } }

      it 'adds success message' do
        put :expected_is_stock, params: params, as: :json

        expect(JSON.parse(response.body)['full_message']).to eq('Статус изменён')
      end
    end

    describe 'PUT #save_recommendation' do
      let(:request) { create(:request_category_one) }
      let(:new_recommendation) { [{ 'name': 'RAM 4Gb' }, { 'name': 'Intel Core i3' }] }
      let(:params) { { id: request.request_id, request: attributes_for(:request_category_one, recommendation_json: new_recommendation) } }

      it 'adds success message' do
        put :save_recommendation, params: params

        expect(JSON.parse(response.body)['full_message']).to eq('Список рекомендаций сохранён')
      end

      context 'when recommendation_json is blank' do
        let!(:params) { { id: request.request_id, request: attributes_for(:request_category_one) } }

        it 'adds full_message error message' do
          put :save_recommendation, params: params

          expect(JSON.parse(response.body)['full_message']).to eq('Recommendation Json не может быть пустым')
        end
      end
    end
  end
end
