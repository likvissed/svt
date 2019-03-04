require 'feature_helper'

module Invent
  RSpec.describe WorkplaceWorker, type: :worker do
    let!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor], status: :confirmed) }

    context 'when workplace does not have responsible user' do
      before { allow_any_instance_of(Workplace).to receive(:user_iss).and_return(nil) }

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
        it 'changes workplace status' do
          subject.perform

          expect(workplace.reload.status).to eq 'freezed'
        end
      end
    end

    context 'when workplace has responsible user' do
      it 'does not change workplace status' do
        subject.perform

        expect(workplace.reload.status).to eq 'confirmed'
      end
    end

    context 'when user division does not match with workplace division' do
      before { allow_any_instance_of(Workplace).to receive_message_chain(:user_iss, :dept).and_return(123) }

      it 'changes workplace status' do
        subject.perform

        expect(workplace.reload.status).to eq 'freezed'
      end
    end

    context 'when workplaces does not have any item' do
      before { allow_any_instance_of(Workplace).to receive(:items).and_return([]) }

      it 'changes workplace status' do
        subject.perform

        expect(workplace.reload.status).to eq 'freezed'
      end
    end

    context 'when workplace has :temporary status' do
      context 'and when it is freezing time' do
        let!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor], status: :temporary, freezing_time: Time.zone.now.to_date) }

        it 'changes workplace status' do
          expect { subject.perform }.to change { workplace.reload.status }.from('temporary').to('freezed')
        end
      end

      context 'and when it is not freezing time' do
        let!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor], status: :temporary, freezing_time: Time.zone.now.to_date + 10.days) }

        it 'does not change workplace status' do
          expect { subject.perform }.not_to change { workplace.reload.status }
        end
      end
    end
  end
end
