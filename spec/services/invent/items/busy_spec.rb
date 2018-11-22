require 'feature_helper'

module Invent
  module Items
    RSpec.describe Busy, type: :model do
      let!(:user) { create(:user) }
      let!(:workplaces) { create_list(:workplace_pk, 2, :add_items, items: %i[pc monitor monitor]) }
      let!(:items) { create_list(:item, 4, :with_property_values, type_name: 'monitor') }
      let(:type) { Type.find_by(name: :pc) }
      let(:item) { workplaces.first.items.first }
      let(:division) { item.workplace.division }
      subject { Busy.new(type.type_id, item.invent_num, item.item_id, division) }

      context 'without invent_num' do
        context 'and with item_id and without division' do
          subject { Busy.new('', '', item.item_id) }

          it 'loads items with specified type and item_id' do
            subject.run
            expect(subject.data[:items].count).to eq 1
            expect(subject.data[:items].first['item_id']).to eq item.item_id
          end
        end

        context 'and without item_id' do
          subject { Busy.new(type.type_id, '', '') }

          it 'returns false' do
            expect(subject.run).to be_falsey
          end
        end
      end

      context 'with division' do
        context 'and when item is not belong to division' do
          subject { Busy.new(type.type_id, item.invent_num, item.item_id, 123) }

          it 'does not show this item in result array' do
            subject.run
            expect(subject.data[:items]).to be_empty
          end
        end
      end

      it 'loads items with specified invent_num, type, invent_num and division' do
        subject.run
        expect(subject.data[:items].count).to eq 1
        expect(subject.data[:items].first['item_id']).to eq item.item_id
      end

      it 'adds :main_info and :full_item_model field to the each item' do
        subject.run
        expect(subject.data[:items].first).to include(:main_info, 'full_item_model')
      end

      context 'when item does not belong to any operation' do
        it 'shows this item in result array' do
          subject.run
          expect(subject.data[:items].first).to include({ item_id: item.id }.as_json)
        end
      end

      context 'when item does not exists' do
        subject { Busy.new(type.type_id, 'error_num', item.item_id, division) }

        its(:run) { is_expected.to be_falsey }

        it 'adds :item_not_found' do
          subject.run
          expect(subject.errors.details[:base]).to include(error: :item_not_found)
        end
      end

      context 'when item belongs to operation with processing status' do
        let!(:operation_1) { create(:order_operation, stockman_id_tn: user.id_tn, status: :done, inv_items: [item]) }
        let!(:operation_2) { create(:order_operation, inv_items: [item]) }
        let!(:order) { create(:order, operation: :in, consumer_id_tn: user.id_tn, operations: [operation_2]) }

        its(:run) { is_expected.to be_falsey }

        it 'adds :item_already_used_in_orders error' do
          subject.run
          expect(subject.errors.details[:base]).to include(error: :item_already_used_in_orders, orders: order.id.to_s)
        end
      end

      context 'when item belongs to operation with done status' do
        let!(:operation) { create(:order_operation, stockman_id_tn: user.id_tn, status: :done, inv_items: [item]) }

        it 'shows this item in result array' do
          subject.run
          expect(subject.data[:items].first).to include({ item_id: item.id }.as_json)
        end
      end
    end
  end
end
