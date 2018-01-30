require 'rails_helper'

module Warehouse
  module Orders
    RSpec.describe Update, type: :model do
      let(:user) { create(:user) }
      subject { Update.new(user, order.warehouse_order_id, order_params) }

      context 'when warehouse_type is :expendable' do
        let!(:order) { create(:order) }
        let(:order_json) { order.as_json }

        context 'and when added a new operations' do
          let(:new_operation) { attributes_for(:order_operation, item_type: 'Флэш-накопитель', item_model: 'Silicon Power') }
          let(:order_params) do
            order_json['operations_attributes'] = order.operations.as_json
            order_json['operations_attributes'] << new_operation
            order_json['operations_attributes'].each do |op|
              op['id'] = op['warehouse_operation_id']

              op.delete('warehouse_operation_id')
            end

            order_json
          end

          its(:run) { is_expected.to be_truthy }

          it 'creates added operations' do
            expect { subject.run }.to change(Operation, :count).by(1)
          end
        end

        context 'and when removed any operation' do
          let(:order_params) do
            order_json['operations_attributes'] = order.operations.as_json
            order_json['operations_attributes'].each_with_index do |op, index|
              op['_destroy'] = 1 if index.zero?
              op['id'] = op['warehouse_operation_id']

              op.delete('warehouse_operation_id')
            end

            order_json
          end

          it 'destroys removed operations' do
            expect { subject.run }.to change(Operation, :count).by(-1)
          end
        end

        context 'and when added operation with invent_num' do
          let(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor monitor]) }
          let(:new_operation) { attributes_for(:order_operation, invent_item_id: workplace.items.first.item_id) }
          let(:order_params) do
            order_json['operations_attributes'] = order.operations.as_json
            order_json['operations_attributes'] << new_operation.as_json
            order_json['operations_attributes'].each_with_index do |op, index|
              op['_destroy'] = 1 if index.zero?
              op['id'] = op['warehouse_operation_id']

              op.delete('warehouse_operation_id')
            end

            order_json
          end

          include_examples 'failed updating on add'
        end
      end

      context 'when warehouse_type is :returnable' do
        let(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor monitor]) }
        let(:operation_1) { attributes_for(:order_operation, invent_item_id: workplace.items.first.item_id) }
        let(:operation_2) { attributes_for(:order_operation, invent_item_id: workplace.items[1].item_id) }
        let(:create_order_params) do
          order = attributes_for(:order, consumer_dept: workplace.workplace_count.division)
          order[:operations_attributes] = [operation_1, operation_2]
          order
        end
        let(:order) { Order.last }
        let(:order_json) { order.as_json }
        let(:execute_order_params) do
          edit = Edit.new(order.warehouse_order_id)
          edit.run
          edit.data[:order]['consumer_tn'] = user.tn
          edit.data[:order]['operations_attributes'].each_with_index do |op, index|
            op['status'] = :done if index.zero?

            op.delete('item')
            op.delete('inv_item')
          end

          edit.data[:order]
        end

        before do
          Create.new(user, create_order_params.as_json).run
          Execute.new(user, order.warehouse_order_id, execute_order_params.as_json).run
          order.reload
        end

        context 'and when added a new operation' do
          let(:new_operation) { attributes_for(:order_operation, invent_item_id: workplace.items[2].item_id) }
          let(:order_params) do
            order_json['operations_attributes'] = order.operations.as_json(include: { item: { include: :inv_item } })
            order_json['operations_attributes'] << new_operation.as_json
            order_json['operations_attributes'].each do |op|
              op['id'] = op['warehouse_operation_id']
              op['invent_item_id'] ||= op['item']['inv_item']['item_id']

              op.delete('warehouse_operation_id')
              op.delete('item')
            end

            order_json
          end

          its(:run) { is_expected.to be_truthy }

          it 'creates a new operation record' do
            expect { subject.run }.to change(Operation, :count).by(1)
          end

          it 'creates a new item_to_order record' do
            expect { subject.run }.to change(ItemToOrder, :count).by(1)
          end

          context 'and when item does not exist' do
            it 'creates warehouse_item record' do
              expect { subject.run }.to change(Item, :count).by(1)
            end

            it 'sets "count" attribute to 0 for each created warehouse_item' do
              subject.run
              expect(Item.last.count).to be_zero
            end
          end

          it 'changes status to :waiting_bring in the each selected item' do
            subject.run
            order_params['operations_attributes'].select { |attr| attr['invent_item_id'] }.reject { |attr| attr['status'] == 'done' }.each do |op|
              expect(Invent::Item.find(op['invent_item_id']).status).to eq 'waiting_bring'
            end
          end

          context 'and when item did not pass validations' do
            before { allow(Item).to receive(:find_or_create_by!).and_raise(ActiveRecord::RecordInvalid) }

            include_examples 'failed updating on add'
          end

          context 'and when item is not created' do
            before { allow(Item).to receive(:find_or_create_by!).and_raise(ActiveRecord::RecordNotSaved) }

            include_examples 'failed updating on add'
          end

          context 'and when order is not updated' do
            before do
              allow(Order).to receive_message_chain(:includes, :find).and_return(order)
              allow(order).to receive(:save).and_return(false)
            end

            include_examples 'failed updating on add'
          end

          context 'and when status of invent_item is not updated' do
            before { allow_any_instance_of(Invent::Item).to receive(:update!).and_raise(ActiveRecord::RecordNotSaved) }

            include_examples 'failed updating on add'
          end

          context 'and when invent_item did not pass validations' do
            before { allow_any_instance_of(Invent::Item).to receive(:update!).and_raise(ActiveRecord::RecordInvalid) }

            include_examples 'failed updating on add'
          end
        end

        context 'and when added item without invent_num' do
          let(:new_operation) { attributes_for(:order_operation) }
          let(:order_params) do
            order_json['operations_attributes'] = order.operations.as_json(include: { item: { include: :inv_item } })
            order_json['operations_attributes'] << new_operation.as_json
            order_json['operations_attributes'].each do |op|
              op['id'] = op['warehouse_operation_id']
              op['invent_item_id'] ||= op['item']['inv_item']['item_id'] if op['item'] && op['item']['inv_item']

              op.delete('warehouse_operation_id')
              op.delete('item')
            end

            order_json
          end

          include_examples 'failed updating models'
        end

        context 'and when removed existing operation' do
          let(:order_params) do
            order_json['operations_attributes'] = order.operations.as_json(include: { item: { include: :inv_item } })
            order_json['operations_attributes'].each do |op|
              op['id'] = op['warehouse_operation_id']
              op['invent_item_id'] ||= op['item']['inv_item']['item_id']

              op.delete('warehouse_operation_id')
              op.delete('item')
            end

            order_json['operations_attributes'].last['_destroy'] = 1
            order_json
          end
          let(:removed_operation) { order_params['operations_attributes'].last }

          its(:run) { is_expected.to be_truthy }

          it 'destroys selected operation' do
            expect { subject.run }.to change(Operation, :count).by(-1)
          end

          it 'destroys a corresponding item_to_order record' do
            expect { subject.run }.to change(ItemToOrder, :count).by(-1)
          end

          it 'does not destroy item record' do
            expect { subject.run }.not_to change(Item, :count)
          end

          it 'sets nil value to the :status attribute into the invent_item record' do
            subject.run
            expect(Invent::Item.find(removed_operation['invent_item_id']).status).to be_nil
          end

          context 'and when order is not updated' do
            before do
              allow(Order).to receive_message_chain(:includes, :find).and_return(order)
              allow(order).to receive(:save).and_return(false)
            end

            include_examples 'failed updating on del'
          end

          context 'and when status of invent_item is not updated' do
            before { allow_any_instance_of(Invent::Item).to receive(:update!).and_raise(ActiveRecord::RecordNotSaved) }

            include_examples 'failed updating on del'
          end

          context 'and when invent_item did not pass validations' do
            before { allow_any_instance_of(Invent::Item).to receive(:update!).and_raise(ActiveRecord::RecordInvalid) }

            include_examples 'failed updating on del'
          end
        end
      end

      context 'when removed all operations' do
        let!(:order) { create(:order) }
        let(:order_json) { order.as_json }
        let(:order_params) do
          order_json['operations_attributes'] = order.operations.as_json
          order_json['operations_attributes'].each do |op|
            op['id'] = op['warehouse_operation_id']
            op['_destroy'] = 1

            op.delete('warehouse_operation_id')
          end

          order_json
        end

        include_examples 'failed updating models'
      end
    end
  end
end
