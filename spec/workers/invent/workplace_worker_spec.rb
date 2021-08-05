require 'feature_helper'

module Invent
  RSpec.describe WorkplaceWorker, type: :worker do
    before do
      allow_any_instance_of(User).to receive(:presence_user_in_users_reference)
      allow_any_instance_of(UserIssByIdTnValidator).to receive(:validate_each)
    end

    let(:employee) { build(:emp_***REMOVED***) }
    let!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor], status: :confirmed) }

    context 'when workplace does not have responsible user' do
      before { allow(UsersReference).to receive(:info_users).and_return([]) }

      %i[pending_verification disapproved freezed].each do |status|
        context "and when workplace has #{status} status" do
          let!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor], status: status) }

          it 'does not change workplace status' do
            subject.perform

            expect(workplace.reload.status).to eq status.to_s
          end
        end
      end

      context 'and when workplace has confirmed status' do
        before { allow(UsersReference).to receive(:info_users).and_return([employee]) }

        it 'changes workplace status' do
          subject.perform

          expect(workplace.reload.status).to eq 'freezed'
        end
      end
    end

    context 'when workplace has responsible user' do
      context 'and when the user dept and workplace division do not match' do
        before { allow(subject).to receive(:ids_workplace).and_return([]) }

        it 'does not change workplace status' do
          subject.perform

          expect(workplace.reload.status).to eq 'confirmed'
        end

        context 'and when the user dept and workplace division are the same' do
          before { allow(subject).to receive(:ids_workplace).and_return([workplace.workplace_id]) }

          it 'does change workplace status' do
            subject.perform

            expect(workplace.reload.status).not_to eq 'confirmed'
          end
        end
      end
    end

    context 'when user division does not match with workplace division' do
      before { allow(UsersReference).to receive(:info_users).and_return([build(:emp_***REMOVED***)]) }

      it 'changes workplace status' do
        subject.perform

        expect(workplace.reload.status).to eq 'freezed'
      end
    end

    context 'when workplaces does not have any item' do
      # before { allow_any_instance_of(Workplace).to receive(:items).and_return([]) }
      before do
        allow_any_instance_of(Workplace).to receive(:items).and_return([])
        allow(subject).to receive(:ids_workplace).and_return([workplace.workplace_id])
      end

      it 'changes workplace status' do
        subject.perform

        expect(workplace.reload.status).to eq 'freezed'
      end
    end

    context 'when workplace has :temporary status' do
      before { allow(UsersReference).to receive(:info_users).and_return([]) }

      context 'and when it is freezing time' do
        let!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor], status: :temporary, freezing_time: Time.zone.now.to_date, comment: 'comment') }

        it 'changes workplace status' do
          expect { subject.perform }.to change { workplace.reload.status }.from('temporary').to('freezed')
        end
      end

      context 'and when it is not freezing time' do
        let!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor], status: :temporary, freezing_time: Time.zone.now.to_date + 10.days, comment: 'comment') }

        it 'does not change workplace status' do
          expect { subject.perform }.not_to change { workplace.reload.status }
        end
      end
    end
  end
end
