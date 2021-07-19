require 'feature_helper'

module Warehouse
  module Orders
    RSpec.describe Swap, type: :model do
      before do
        allow_any_instance_of(Order).to receive(:set_consumer)
        allow_any_instance_of(Order).to receive(:find_employee_by_workplace).and_return([build(:emp_***REMOVED***)])
      end

      let!(:current_user) { create(:user) }
      let!(:workplace_1) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
      let!(:workplace_2) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
      let!(:workplace_3) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
      let(:swap_items) { [workplace_2.items.last.item_id, workplace_3.items.first.item_id] }
      subject { Swap.new(current_user, workplace_1.workplace_id, swap_items) }

      context 'when present property with barcode fo item' do
        let(:property_with_barcode) { Invent::Property.find_by(short_description: Invent::Property::LIST_TYPE_FOR_BARCODES.first.capitalize) }
        let(:inv_property_value) { create(:property_value, property: property_with_barcode, item: workplace_2.items.last) }
        let(:warehouse_item) do
          w_item = create(:used_item, warehouse_type: :without_invent_num, count: 2, count_reserved: 1, item_type: 'Картридж', item_model: '6515DNI')
          w_item.build_barcode_item
          w_item.invent_property_value = inv_property_value

          w_item.save(validate: false)
          w_item
        end

        before { workplace_2.items.last.warehouse_items = [warehouse_item] }

        it 'creates warehouse_operations records' do
          expect { subject.run }.to change(Operation, :count).by(swap_items.size * 2 + (workplace_2.items.last.warehouse_items.size * 2))
        end

        it 'ets fields the each operation' do
          subject.run

          Order.all.includes(:operations).each do |order|
            order.operations.each do |op|
              if op.operationable.operation == 'in'
                expect(op.shift).to eq(1)
              elsif op.operationable.operation == 'out'
                expect(op.shift).to eq(-1)
              end

              next if op.item_type != warehouse_item.item_type

              expect(op.status).to eq 'done'
              expect(op.item_type).to eq warehouse_item.item_type
              expect(op.item_model).to eq warehouse_item.item_model
              expect(op.item_id).to eq warehouse_item.id
              expect(op.stockman_id_tn).to eq current_user.id_tn
              expect(op.stockman_fio).to eq current_user.fullname
            end
          end
        end
      end

      it 'creates warehouse_operations records' do
        expect { subject.run }.to change(Operation, :count).by(swap_items.size * 2)
      end

      it 'creates warehouse_item_to_orders records' do
        expect { subject.run }.to change(InvItemToOperation, :count).by(swap_items.size * 2)
      end

      it 'creates as many warehouse_orders as the number of workplaces is specified' do
        expect { subject.run }.to change(Order, :count).by(2 * 2)
      end

      it 'sets :done to the each operation attribute' do
        subject.run
        Order.all.includes(:operations).each do |o|
          o.operations.each do |op|
            expect(op.status).to eq 'done'
          end
        end
      end

      it 'sets stockman to the each operation' do
        subject.run

        Order.all.includes(:operations).each do |o|
          o.operations.each do |op|
            expect(op.stockman_id_tn).to eq current_user.id_tn
            expect(op.stockman_fio).to eq current_user.fullname
          end
        end
      end

      it 'sets :done to the order status' do
        subject.run
        Order.all.each { |o| expect(o.done?).to be_truthy }
      end

      it 'creates items' do
        expect { subject.run }.to change(Item, :count).by(2)
      end

      it 'sets count of items to 0' do
        subject.run

        Order.all.includes(operations: :item).each do |o|
          o.operations.each do |op|
            expect(op.item.count).to eq 0
          end
        end
      end

      it 'sets count_reserved of items to 0' do
        subject.run

        Order.all.includes(operations: :item).each do |o|
          o.operations.each do |op|
            expect(op.item.count_reserved).to eq 0
          end
        end
      end

      it 'sets new :workplace to each inv_item' do
        subject.run

        Order.all.includes(:inv_items).each do |o|
          o.inv_items.each { |i| expect(i.workplace).to eq workplace_1 }
        end
      end

      it 'sets a :in_workplace status to each inv_item' do
        subject.run

        Order.all.includes(:inv_items).each do |o|
          o.inv_items.each { |i| expect(i.status).to eq 'in_workplace' }
        end
      end

      context 'when one of item from another division' do
        let!(:workplace_4) { create(:workplace_pk, :add_items, items: %i[pc monitor], dept: ***REMOVED***) }
        let(:swap_items) { [workplace_2.items.last.item_id, workplace_4.items.first.item_id] }

        its(:run) { is_expected.to be_truthy }

        # it 'does not create any order' do
        #   expect { subject.run }.not_to change(Order, :count)
        # end

        it 'creates as many warehouse_orders as the number of workplaces is specified' do
          expect { subject.run }.to change(Order, :count).by(2 * 2)
        end

        it 'does not change :workplace attribute of selected items' do
          subject.run

          expect(workplace_1.reload.items.count).to eq 4
          expect(workplace_2.reload.items.count).to eq 1
          expect(workplace_4.reload.items.count).to eq 1
        end
      end

      context 'when item already belongs to processing order' do
        let(:inv_item) { workplace_3.items.first }
        let(:item) { create(:used_item, inv_item: inv_item) }
        let(:operation) { build(:order_operation, item: item, inv_items: [inv_item]) }
        let!(:order) { create(:order, inv_workplace: workplace_3, operation: :in, operations: [operation]) }

        its(:run) { is_expected.to be_falsey }

        it 'does not create any order' do
          expect { subject.run }.not_to change(Order, :count)
        end

        it 'does not change :workplace attribute of selected items' do
          subject.run
          expect(inv_item.reload.workplace).to eq workplace_3
          expect(workplace_2.reload.items.count).to eq 2
          expect(workplace_1.reload.items.count).to eq 2
        end
      end
    end
  end
end
