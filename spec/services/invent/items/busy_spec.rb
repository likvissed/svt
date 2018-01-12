require 'spec_helper'

module Invent
  module Items
    RSpec.describe Busy, type: :model do
      let!(:workplaces) { create_list(:workplace_pk, 2, :add_items, items: %i[pc monitor monitor]) }
      let!(:items) { create_list(:item, 4, :with_property_values, type_name: 'monitor') }
      let(:type) { Type.find_by(name: :pc) }
      let(:item) { workplaces.first.items.first }
      subject { Busy.new(type.type_id, item.invent_num) }

      context 'without invent_num' do
        subject { Busy.new(type.type_id, '') }

        it 'returns false' do
          expect(subject.run).to be_falsey
        end
      end

      it 'loads items with specified type and invent_num' do
        subject.run
        expect(subject.data.count).to eq 1
      end

      it 'adds :main_info and :add_info field to the each item' do
        subject.run
        expect(subject.data.first).to include(:main_info, 'get_item_model')
      end

      context 'when item belongs to order with processing status' do
        let(:operations) { [build(:order_operation, invent_item_id: item.item_id)] }
        let(:item_to_orders) { [build(:item_to_order, inv_item: item)] }
        let!(:order) { create(:order, consumer_dept: item.workplace.workplace_count.division, operations: operations, item_to_orders: item_to_orders) }
        subject { Busy.new(item.type.type_id, item.invent_num) }

        it 'does not show this item in result array' do
          subject.run
          expect(subject.data).to be_empty
        end
      end
    end
  end
end
