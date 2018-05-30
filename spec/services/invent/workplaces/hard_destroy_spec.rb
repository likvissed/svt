require 'feature_helper'

module Invent
  module Workplaces
    RSpec.describe HardDestroy, type: :model do
      let!(:user) { create(:user) }
      let!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
      subject { HardDestroy.new(user, workplace.workplace_id) }

      its(:run) { is_expected.to be_truthy }

      it 'destroyes workplace' do
        expect { subject.run }.to change(Workplace, :count).by(-1)
      end

      it 'destroyes items' do
        expect { subject.run }.to change(Item, :count).by(-workplace.items.count)
      end

      it 'broadcasts to workplaces' do
        expect(subject).to receive(:broadcast_workplaces)
        subject.run
      end

      it 'broadcasts to items' do
        expect(subject).to receive(:broadcast_items)
        subject.run
      end

      context 'when workplace was not destroyed' do
        before { allow_any_instance_of(Workplace).to receive(:destroy).and_return(false) }

        it 'does not destroy items' do
          expect { subject.run }.not_to change(Item, :count)
        end

        its(:run) { is_expected.to be_falsey }
      end

      context 'when item belongs to processing order' do
        let!(:order) { create(:order, inv_workplace: workplace) }

        it 'does not destroy item' do
          expect { subject.run }.not_to change(Item, :count)
        end

        it 'does not destroy warehouse_item' do
          expect { subject.run }.not_to change(Warehouse::Item, :count)
        end

        it 'does not destroy warehouse_inv_item_to_operations' do
          expect { subject.run }.not_to change(Warehouse::InvItemToOperation, :count)
        end
      end
    end
  end
end