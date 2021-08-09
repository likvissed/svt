require 'feature_helper'

module Invent
  RSpec.describe UserWorker, type: :worker do
    before { allow_any_instance_of(User).to receive(:presence_user_in_users_reference) }
    let(:user) { create(:user) }
    let!(:workplace_count) { create(:active_workplace_count, division: ***REMOVED***, users: [user]) }

    describe '#delete_fired_users' do
      context 'when user is fired' do
        before { allow(subject).to receive(:ids_fired_users).and_return([user.id]) }

        it 'deletes user record' do
          expect { subject.perform }.to change(User, :count).by(-1)
        end

        it 'deletes invent_workplace_responsibles record' do
          expect { subject.perform }.to change(Invent::WorkplaceResponsible, :count).by(-1)
        end
      end

      context 'when user is not fired' do
        before { allow(subject).to receive(:ids_fired_users).and_return([]) }

        it 'not change count users' do
          expect { subject.perform }.not_to change(User, :count)
        end

        it 'not change count invent_workplace_responsibles' do
          expect { subject.perform }.not_to change(Invent::WorkplaceResponsible, :count)
        end
      end
    end
  end
end
