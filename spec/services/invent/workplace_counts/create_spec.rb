require 'feature_helper'

module Invent
  module WorkplaceCounts
    RSpec.describe Create, type: :model do
      skip_users_reference

      let(:emp_user) { build(:emp_***REMOVED***) }
      let(:result_user_reference) { [emp_user] }

      let!(:current_user) { create(:user) }
      let(:user_new) { build(:***REMOVED***_user) }
      let(:workplace_count_params) { build(:active_workplace_count).as_json }
      before do
        allow_any_instance_of(Create).to receive(:find_user_reference).and_return(result_user_reference)

        workplace_count_params[:user_ids] = []
        workplace_count_params[:users_attributes] = [user_new.as_json]
      end

      subject { Create.new(current_user, workplace_count_params) }

      context 'when created valid workplace_count' do
        it 'increments count of workplace_count' do
          expect { subject.run }.to change { WorkplaceCount.count }.by(1)
        end

        it 'returns true' do
          expect(subject.run).to be true
        end

        it 'increments count of User' do
          expect { subject.run }.to change { User.count }.by(1)
        end
      end

      context 'when the phone is entered manually' do
        let(:user) { create(:***REMOVED***_user) }
        before do
          user.phone = '11-22'
          workplace_count_params[:users_attributes] = [user.as_json.symbolize_keys]
        end

        it 'сhange the phone in User' do
          subject.run

          expect(user.phone).to eq User.find_by(tn: user.tn).phone
        end
      end

      context 'when users_attributes is blank' do
        before { workplace_count_params[:users_attributes] = [] }

        it 'returns with error :add_at_least_one_responsible' do
          subject.run

          expect(subject.error).to include(:object, full_message: 'Необходимо добавить ответственного')
        end

        it 'returns false' do
          expect(subject.run).to be false
        end
      end

      context 'when adds new user' do
        let(:role_id_***REMOVED***_user) { Role.find_by(name: '***REMOVED***_user').id }
        let(:user) { User.find_by(tn: user_new.tn) }

        it 'assigned a new role as :***REMOVED***_user' do
          subject.run

          expect(user.role_id).to eq role_id_***REMOVED***_user
        end
      end

      context 'when adds present user' do
        let(:role_id_admin) { Role.find_by(name: 'admin').id }
        let!(:tyulyakova_user) { create(:tyulyakova_user, role_id: role_id_admin) }

        before { workplace_count_params[:users_attributes] = [tyulyakova_user.as_json.symbolize_keys] }

        it 'not changed the role' do
          subject.run

          expect(User.find_by(tn: tyulyakova_user.tn).role_id).to eq role_id_admin
        end
      end
    end
  end
end
