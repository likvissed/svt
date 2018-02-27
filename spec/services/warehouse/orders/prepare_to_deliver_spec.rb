require 'feature_helper'

module Warehouse
  module Orders
    RSpec.describe PrepareToDeliver, type: :model do
      let!(:current_user) { create(:***REMOVED***_user) }
      subject { PrepareToDeliver.new(current_user, order.id, order_params) }

      # Техника Б/У с инв. номером
      let(:first_inv_item) { create(:item, :with_property_values, type_name: :pc, status: :waiting_take) }
      let(:sec_inv_item) { create(:item, :with_property_values, type_name: :monitor) }
      # Техника новая, прикрепленная к РМ (и ожидающая выдачи)
      let(:fourth_inv_item) { create(:item, type_name: :monitor, disable_filters: true, status: :waiting_take, invent_num: nil) }
      let(:fifth_inv_item) { create(:item, type_name: :monitor, disable_filters: true, status: :waiting_take, invent_num: nil) }
      let(:sixth_inv_item) { create(:item, type_name: :monitor, disable_filters: true, status: :waiting_take, invent_num: nil) }
      let(:workplace) do
        wp = build(:workplace_pk, items: [first_inv_item, sec_inv_item], dept: ***REMOVED***)
        wp.save(validate: false)
        wp
      end
      # Это будет выдаваться
      let(:first_item) { create(:used_item, inv_item: first_inv_item) }
      let(:sec_item) { create(:used_item, inv_item: sec_inv_item) }
      # Это будет выдаваться
      let(:third_item) { create(:used_item, warehouse_type: :without_invent_num, item_type: 'test type', item_model: 'test model') }
      # Это будет выдаваться
      let(:fourth_item) { create(:new_item, inv_item: nil, inv_type: fourth_inv_item.type, inv_model: fourth_inv_item.model, count: 5, count_reserved: 3) }
      let(:operations) do
        [
          build(:order_operation, item: first_item, inv_item_ids: [first_inv_item.item_id], shift: -1),
          build(:order_operation, item: sec_item, inv_item_ids: [sec_inv_item.item_id], shift: -1),
          build(:order_operation, item: third_item, shift: -1),
          build(:order_operation, item: fourth_item, inv_item_ids: [fourth_inv_item.item_id, fifth_inv_item.item_id, sixth_inv_item.item_id], shift: -3),
        ]
      end
      let!(:order) do
        o = build(:order, inv_workplace: workplace, operation: :out, operations: operations)
        o.save(validate: false)
        o
      end
      let(:order_json) { order.as_json }

      context 'and when user selected items with different types' do
        let(:order_params) do
          order_json['consumer_tn'] = ***REMOVED***
          order_json['operations_attributes'] = operations.as_json
          order_json['operations_attributes'].each_with_index do |op, index|
            op['status'] = 'done' if [0, 2, 3].include?(index)
          end
          order_json
        end

        include_examples 'prepare_to_deliver specs'

        it 'sets :id of selected orders to the :selected_op element' do
          subject.run
          subject.data[:selected_op].each do |sel|
            expect(sel).to include('id')
          end
          expect(subject.data[:selected_op].first['id']).to eq order.operations.first.id
        end

        it 'sets :done status to selected operations' do
          subject.run
          subject.data[:operations_attributes].each_with_index do |op, index|
            next unless [0, 2, 3].include?(index)

            expect(op['status'].to_s).to eq 'done'
          end
        end
      end

      context 'and when user does not selected any operation' do
        let(:order_params) do
          order_json['consumer_tn'] = ***REMOVED***
          order_json['operations_attributes'] = operations.as_json
          order_json
        end

        it 'adds :operation_not_selected error' do
          subject.run

          expect(subject.error[:full_message]).to eq 'Необходимо выбрать хотя бы одну позицию'
        end

        its(:run) { is_expected.to be_falsey }
      end

      context 'and when user selected items with the same types' do
        let(:order_params) do
          order_json['consumer_tn'] = ***REMOVED***
          order_json['operations_attributes'] = operations.as_json
          order_json['operations_attributes'].each_with_index do |op, index|
            op['status'] = 'done' if [0, 1, 2, 3].include?(index)
          end
          order_json
        end

        include_examples 'prepare_to_deliver specs'

        it 'sets :done status to selected operations' do
          subject.run
          subject.data[:operations_attributes].each_with_index do |op, index|
            next unless [0, 1, 2, 3].include?(index)

            expect(op['status'].to_s).to eq 'done'
          end
        end
      end
    end
  end
end
