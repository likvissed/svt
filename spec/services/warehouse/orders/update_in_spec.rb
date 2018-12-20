require 'feature_helper'

module Warehouse
  module Orders
    RSpec.describe UpdateIn, type: :model do
      let!(:user) { create(:user) }
      let(:new_user) { create(:***REMOVED***_user, role: Role.find_by(name: :admin)) }
      subject { UpdateIn.new(new_user, order.id, order_params) }

      context 'when warehouse_type is :without_invent_num' do
        let!(:order) { create(:order) }
        let(:order_json) { order.as_json }

        context 'and when :operation attribute changes to :out' do
          let(:order_params) { order_json.tap { |o| o['operation'] = 'out' } }

          include_examples 'order error format'
        end

        context 'and when :shift attribute changes to negative value' do
          let(:order_params) do
            order_json.tap do |o|
              o['operations_attributes'] = order.operations.as_json
              o['operations_attributes'].first['shift'] = -3
            end
          end

          its(:run) { is_expected.to be_falsey }
          # include_examples 'order error format'
        end

        context 'and when added a new operations' do
          let(:new_operation) { attributes_for(:order_operation, item_type: 'Флэш-накопитель', item_model: 'Silicon Power') }
          let(:order_params) do
            order_json['operations_attributes'] = order.operations.as_json
            order_json['operations_attributes'] << new_operation.as_json

            order_json
          end

          include_examples 'updating :in order'

          it 'creates added operations' do
            expect { subject.run }.to change(Operation, :count).by(1)
          end
        end

        context 'and when removed any operation' do
          let(:order_params) do
            order_json['operations_attributes'] = order.operations.as_json
            order_json['operations_attributes'].each_with_index do |op, index|
              op['_destroy'] = 1 if index.zero?
            end

            order_json
          end

          include_examples 'updating :in order'

          it 'destroys removed operations' do
            expect { subject.run }.to change(Operation, :count).by(-1)
          end
        end

        context 'and when added operation with invent_num' do
          let(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor monitor]) }
          let(:new_operation) { attributes_for(:order_operation, inv_item_ids: [workplace.items.first.item_id]) }
          let(:order_params) do
            order_json['operations_attributes'] = order.operations.as_json
            order_json['operations_attributes'] << new_operation.as_json
            order_json['operations_attributes'].each_with_index do |op, index|
              op['_destroy'] = 1 if index.zero?
            end

            order_json
          end

          include_examples 'failed updating :in on add'
        end
      end

      context 'when warehouse_type is :with_invent_num' do
        let(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor monitor]) }
        let(:operation_1) { attributes_for(:order_operation, inv_item_ids: [workplace.items.first.item_id]) }
        let(:operation_2) { attributes_for(:order_operation, inv_item_ids: [workplace.items[1].item_id]) }
        let(:create_order_params) do
          order = attributes_for(:order, consumer_dept: workplace.workplace_count.division)
          order[:operations_attributes] = [operation_1, operation_2]
          order
        end
        let(:order) { Order.last }
        let(:order_json) { order.as_json }
        let(:execute_order_params) do
          edit = Edit.new(order.id)
          edit.run
          edit.data[:order]['consumer_tn'] = user.tn
          edit.data[:order]['operations_attributes'].each_with_index do |op, index|
            op['status'] = 'done' if index.zero?

            op.delete('item')
            op.delete('inv_items')
            op.delete('inv_item_ids')
            op.delete('formatted_date')
          end

          edit.data[:order].delete('consumer_obj')
          edit.data[:order]
        end

        before do
          CreateIn.new(user, create_order_params.as_json).run
          ExecuteIn.new(user, order.id, execute_order_params.as_json).run
          order.reload
        end

        context 'and when added a new operation' do
          let(:new_operation) { attributes_for(:order_operation, inv_item_ids: [workplace.items[2].item_id]) }
          let(:order_params) do
            order_json['operations_attributes'] = order.operations.as_json
            order_json['operations_attributes'] << new_operation.as_json
            order_json
          end

          include_examples 'updating :in order'

          it 'creates a new operation record' do
            expect { subject.run }.to change(Operation, :count).by(1)
          end

          it 'creates a new item_to_order record' do
            expect { subject.run }.to change(InvItemToOperation, :count).by(1)
          end

          it 'broadcasts to items' do
            expect(subject).to receive(:broadcast_items)
            subject.run
          end

          it 'broadcasts to in_orders' do
            expect(subject).to receive(:broadcast_in_orders)
            subject.run
          end

          context 'and when item does not exist' do
            it 'creates warehouse_item record' do
              expect { subject.run }.to change(Item, :count).by(1)
            end

            it 'sets "count" attribute to 0 for each created warehouse_item' do
              subject.run
              expect(Item.last.count).to be_zero
            end

            it 'sets item data to the corresponding operation and warehouse_item records' do
              subject.run

              expect(Operation.last.item).to eq Item.last
              expect(Item.last.inv_item).to eq workplace.items[2]
              # expect(Item.last.item_model).to eq workplace.items[2].full_item_model
            end
          end

          context 'and when item already exists' do
            before { create(:used_item, inv_item: workplace.items[2], item_model: 'qwerty') }

            it 'sets item data to the corresponding operation and warehouse_item records' do
              subject.run

              expect(Item.last.item_model).to eq workplace.items[2].full_item_model
            end

            context 'and when order was not saved' do
              before do
                allow(Order).to receive(:find).and_return(order)
                allow(order).to receive(:save).and_return(false)
              end

              it 'does not change warehouse_item' do
                expect(Item.last.item_model).to eq 'qwerty'
              end
            end
          end

          it 'changes status to :waiting_bring in the each selected item' do
            subject.run

            order_params['operations_attributes'].select { |attr| attr['inv_item_ids'] }.reject { |attr| attr['status'] == 'done' }.each do |op|
              expect(Invent::Item.find(op['inv_item_ids'].first).status).to eq 'waiting_bring'
            end
          end

          context 'and when item did not pass validations' do
            before { allow(Item).to receive(:find_or_create_by!).and_raise(ActiveRecord::RecordInvalid) }

            include_examples 'failed updating :in on add'
          end

          context 'and when item is not created' do
            before { allow(Item).to receive(:find_or_create_by!).and_raise(ActiveRecord::RecordNotSaved) }

            include_examples 'failed updating :in on add'
          end

          context 'and when order is not updated' do
            before { allow_any_instance_of(Order).to receive(:save).and_return(false) }

            include_examples 'failed updating :in on add'
          end

          context 'and when status of invent_item is not updated' do
            before { allow_any_instance_of(Invent::Item).to receive(:update!).and_raise(ActiveRecord::RecordNotSaved) }

            include_examples 'failed updating :in on add'
          end

          context 'and when invent_item did not pass validations' do
            before { allow_any_instance_of(Invent::Item).to receive(:update!).and_raise(ActiveRecord::RecordInvalid) }

            include_examples 'failed updating :in on add'
          end
        end

        context 'and when added item without invent_num' do
          let(:new_operation) { attributes_for(:order_operation) }
          let(:order_params) do
            order_json['operations_attributes'] = order.operations.as_json
            order_json['operations_attributes'] << new_operation.as_json

            order_json
          end

          include_examples 'failed updating :in order'
        end

        context 'and when removed existing operation' do
          let(:destroyed) { order.operations.last }
          let!(:updated_item) { destroyed.inv_items.first }
          let(:order_params) do
            order_json['operations_attributes'] = order.operations.as_json
            order_json['operations_attributes'].last['_destroy'] = 1
            order_json
          end
          let(:removed_operation) { order_params['operations_attributes'].last }

          include_examples 'updating :in order'

          it 'destroys selected operation' do
            expect { subject.run }.to change(Operation, :count).by(-1)
          end

          it 'destroys a corresponding item_to_order record' do
            expect { subject.run }.to change(InvItemToOperation, :count).by(-1)
          end

          it 'does not destroy item record' do
            expect { subject.run }.not_to change(Item, :count)
          end

          it 'sets nil value to the :status attribute into the invent_item record' do
            subject.run

            expect(updated_item.reload.status).to eq 'in_workplace'
          end

          context 'and when order is not updated' do
            before do
              allow(Order).to receive(:find).and_return(order)
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

        context 'and when remove done operation' do
          let(:order_params) do
            order_json['operations_attributes'] = order.operations.as_json
            order_json['operations_attributes'].each_with_index do |op, index|
              op['_destroy'] = 1 if index.zero?
            end
            order_json
          end

          its(:run) { is_expected.to be_falsey }

          it 'adds transalted errors from operations to the :full_message variable' do
            subject.run
            expect(subject.error[:full_message]).to match(/Невозможно удалить исполненную операцию/)
          end
        end
      end

      context 'when removed all operations' do
        let!(:order) { create(:order) }
        let(:order_json) { order.as_json }
        let(:order_params) do
          order_json['operations_attributes'] = order.operations.as_json
          order_json['operations_attributes'].each { |op| op['_destroy'] = 1 }
          order_json
        end

        include_examples 'failed updating :in order'
      end
    end
  end
end
