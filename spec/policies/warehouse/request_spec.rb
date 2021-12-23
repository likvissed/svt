require 'spec_helper'

module Warehouse
  RSpec.describe RequestPolicy do
    let(:***REMOVED***_user) { create(:***REMOVED***_user) }
    let(:manager) { create(:***REMOVED***_user) }
    let(:worker) { create(:shatunova_user) }
    let(:read_only) { create(:tyulyakova_user) }
    before do
      allow_any_instance_of(User).to receive(:presence_user_in_users_reference)
      create(:request_category_one)
    end
    subject { RequestPolicy }

    permissions :ctrl_access? do
      let(:model) { Request.first }

      include_examples 'policy not for ***REMOVED***_user'
    end

    permissions :index? do
      let(:model) { Request.first }

      include_examples 'policy for worker'
    end

    permissions :edit? do
      let(:model) { Request.first }

      include_examples 'policy not for ***REMOVED***_user'
    end

    permissions :send_for_analysis? do
      let(:model) { Request.first }

      include_examples 'policy for manager'
    end

    permissions :assign_new_executor? do
      let(:model) { Request.first }

      include_examples 'policy for manager'
    end

    permissions :close? do
      let(:request) { create(:request_category_one) }

      context 'with :manager role and with valid user' do
        it 'grants access to the request' do
          expect(subject).to permit(manager, Request.find(request.request_id))
        end
      end

      context 'with :***REMOVED***_user role and with invalid user' do
        it 'denies access to the request' do
          expect(subject).not_to permit(***REMOVED***_user, Request.find(request.request_id))
        end
      end
    end

    permissions :send_for_confirm? do
      let(:model) { Request.first }

      include_examples 'policy for manager'
    end

    permissions :send_to_owner? do
      let(:model) { Request.first }

      include_examples 'policy for manager'
    end

    permissions :ready? do
      let(:request) { create(:request_category_one) }

      context 'with :manager role and with valid user' do
        it 'grants access to the request' do
          expect(subject).to permit(manager, Request.find(request.request_id))
        end
      end

      context 'with :***REMOVED***_user role and with invalid user' do
        it 'denies access to the request' do
          expect(subject).not_to permit(***REMOVED***_user, Request.find(request.request_id))
        end
      end
    end

    permissions :send_answer_to_user? do
      let(:model) { Request.first }

      include_examples 'policy for manager'
    end

    permissions :update? do
      let(:request) { create(:request_category_one) }

      context 'with :manager role and with valid user' do
        it 'grants access to the request' do
          expect(subject).to permit(manager, Request.find(request.request_id))
        end
      end

      context 'with :***REMOVED***_user role and with invalid user' do
        it 'denies access to the request' do
          expect(subject).not_to permit(***REMOVED***_user, Request.find(request.request_id))
        end
      end
    end

    permissions :save_recommendation? do
      let(:request) { create(:request_category_one) }

      context 'with :manager role and with valid user' do
        it 'grants access to the request' do
          expect(subject).to permit(manager, Request.find(request.request_id))
        end
      end

      context 'with :***REMOVED***_user role and with invalid user' do
        it 'denies access to the request' do
          expect(subject).not_to permit(***REMOVED***_user, Request.find(request.request_id))
        end
      end
    end

    permissions :expected_is_stock? do
      let(:request) { create(:request_category_one) }

      context 'with :manager role and with valid user' do
        it 'grants access to the request' do
          expect(subject).to permit(manager, Request.find(request.request_id))
        end
      end

      context 'with :***REMOVED***_user role and with invalid user' do
        it 'denies access to the request' do
          expect(subject).not_to permit(***REMOVED***_user, Request.find(request.request_id))
        end
      end
    end
  end
end
