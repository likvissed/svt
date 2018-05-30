require 'feature_helper'

module Warehouse
  module Supplies
    RSpec.describe Destroy, type: :model do
      let(:user) { create(:user) }
      let!(:supply) { create(:supply) }
      let!(:counts) { Item.pluck(:count) }
      subject { Destroy.new(user, supply.id) }

      its(:run) { is_expected.to be_truthy }

      it 'destroyes supply' do
        expect { subject.run }.to change(Supply, :count).by(-1)
      end

      it 'destroyes operations' do
        expect { subject.run }.to change(Operation, :count).by(-2)
      end

      it 'changes :count attribute of corresponding items' do
        subject.run
        Item.find_each do |item|
          expect(item.count).to be_zero
        end
      end

      context 'when item was not updated' do
        before { allow_any_instance_of(Item).to receive(:save!).and_raise(ActiveRecord::RecordNotSaved) }

        its(:run) { is_expected.to be_falsey }

        it 'does not destroy supply' do
          expect { subject.run }.not_to change(Supply, :count)
        end

        it 'does not destroy operations' do
          expect { subject.run }.not_to change(Operation, :count)
        end

        it 'does not change :count attribute of corresponding items' do
          counts.each_with_index do |count, index|
            expect(Item.all[index].count).to eq count
          end
        end
      end

      context 'when supply was not destroyed' do
        before { allow_any_instance_of(Supply).to receive(:destroy).and_return(false) }

        its(:run) { is_expected.to be_falsey }

        it 'does not change :count attribute of corresponding items' do
          counts.each_with_index do |count, index|
            expect(Item.all[index].count).to eq count
          end
        end
      end
    end
  end
end
