require 'feature_helper'

module Invent
  module WorkplaceCounts
    RSpec.describe Create, type: :model do
      let(:role) { create(:***REMOVED***_user_role) }
      let(:user) { attributes_for(:user, role_id: role.id).except(:id_tn, :division, :email, :login, :fullname) }
      let(:***REMOVED***_user) { attributes_for(:***REMOVED***_user).except(:id_tn, :division, :email, :login, :fullname) }
      let(:workplace_count) { attributes_for(:active_workplace_count, users_attributes: [user, ***REMOVED***_user]) }
      subject { Create.new(workplace_count) }

      include_examples 'run methods', 'save_workplace'
      it 'assign @data to WorkplaceCount instance' do
        subject.run
        expect(subject.data).to be_instance_of WorkplaceCount
      end

      context 'with valid params' do
        its(:run) { is_expected.to be_truthy }

        it 'broadcasts to users' do
          expect(subject).to receive(:broadcast_users)
          subject.run
        end

        it 'broadcasts to users' do
          expect(subject).to receive(:broadcast_users)
          subject.run
        end
      end

      context 'with invalid params' do
        let(:workplace_count) { attributes_for(:active_workplace_count) }

        its(:run) { is_expected.to be_falsey }
        it 'includes object and full_message keys into the @error object' do
          subject.run
          expect(subject.error).to include(:object, :full_message)
        end
      end
    end
  end
end
