require 'rails_helper'

module Warehouse
  RSpec.describe ItemToOrder, type: :model do
    it { is_expected.to belong_to(:inv_item).class_name('Invent::Item').with_foreign_key('invent_item_id') }
    it { is_expected.to belong_to(:order) }

    describe '#uniq_inv_item_for_processing_order' do
      let(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor monitor]) }
      let(:item) { workplace.items.first }
      subject { build(:item_to_order, inv_item: item) }

      context 'when order exists' do
        let(:operations) { [build(:order_operation, invent_item_id: item.item_id)] }
        let(:item_to_orders) { [build(:item_to_order, inv_item: item)] }
        let!(:order) { create(:order, consumer_dept: item.workplace.workplace_count.division, operations: operations, item_to_orders: item_to_orders) }

        it 'adds :uniq_by_processing_order error' do
          subject.valid?
          expect(subject.errors.details[:inv_item]).to include(
            error: :uniq_by_processing_order,
            type: item.type.short_description,
            invent_num: item.invent_num,
            order_id: order.warehouse_order_id
          )
        end
      end

      it { is_expected.to be_valid }

      context 'when operation has :operation_already_exists error' do
        let!(:order) { create(:order) }
        subject { build(:item_to_order, inv_item: item, order: order) }
        before { allow_any_instance_of(Order).to receive_message_chain(:errors, :details, :[], :any?).and_return(true) }

        it { is_expected.to be_valid }
      end
    end
  end
end
