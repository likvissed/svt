require 'feature_helper'

module Warehouse
  module Orders
    RSpec.describe UpdateOut, type: :model do
      before do
        allow_any_instance_of(Order).to receive(:set_consumer).and_return([employee])
        allow_any_instance_of(Order).to receive(:find_employee_by_workplace).and_return([employee])
      end
      let(:employee) { build(:emp_***REMOVED***) }

      let(:user) { create(:***REMOVED***_user) }
      let(:new_user) { create(:***REMOVED***_user, role: create(:manager_role)) }
      let(:pc_type) { Invent::Type.find_by(name: :pc) }
      let!(:pc_items) { create(:new_item, inv_type: pc_type, item_model: 'Unit', count: 20, invent_num_end: 131) }
      let(:mon_type) { Invent::Type.find_by(name: :monitor) }
      let!(:monitor_items) { create(:new_item, inv_type: mon_type, inv_model: mon_type.models.first, count: 25, invent_num_end: 135) }
      let(:mfu_type) { Invent::Type.find_by(name: :mfu) }
      let(:inv_mfu_item) { create(:item, :with_property_values, type_name: :mfu) }
      let!(:mfu_items) { create(:used_item, inv_item: inv_mfu_item, count: 1) }
      subject { UpdateOut.new(new_user, order.id, order_params) }

      context 'when warehouse_type is :without_invent_num' do
        let!(:order) { create(:order, creator_id_tn: user.id_tn, operation: :out, validator_id_tn: user.id_tn) }
        let(:order_json) { order.as_json }

        context 'and when :operation attribute changes to :in' do
          let(:order_params) { order_json.tap { |o| o['operation'] = 'in' } }

          include_examples 'order error format'
        end

        context 'and when :shift attribute changes to negative value' do
          let(:order_params) do
            order_json.tap do |o|
              o['operations_attributes'] = order.operations.as_json
              o['operations_attributes'].first['shift'] = 3
            end
          end

          include_examples 'order error format'
        end

        context 'and when increased :shift attribute' do
          let(:changed_op) { order.operations.first }
          let(:item_of_changed_op) { changed_op.item }
          let(:order_params) do
            order_json.tap do |o|
              o['operations_attributes'] = order.operations.as_json
              o['operations_attributes'].first['shift'] = -1
            end
          end

          include_examples 'updating order'

          it 'sets a new shift value' do
            expect { subject.run }.to change { changed_op.reload.shift }.by(1)
          end

          it 'changes count_reserved' do
            subject.run

            expect(item_of_changed_op.reload.count_reserved).to eq 1
          end

          it 'does not create inv_item' do
            expect { subject.run }.not_to change(Invent::Item, :count)
          end
        end

        context 'and when reduced :shift attribute' do
          let(:changed_op) { order.operations.first }
          let(:item_of_changed_op) { changed_op.item }

          context 'and when new :shift value (absolute value) is less than allowable value' do
            let(:order_params) do
              order_json.tap do |o|
                o['operations_attributes'] = order.operations.as_json
                o['operations_attributes'].first['shift'] = -333
              end
            end

            include_examples 'failed updating :out'

            it 'does not change :count_reserved attribute' do
              expect { subject.run }.not_to change { item_of_changed_op.reload.count_reserved }
            end

            it 'does not change :shift attribute' do
              expect { subject.run }.not_to change { changed_op.reload.shift }
            end
          end

          context 'and when new :shift value (absolute value) is greater than allowable value' do
            let(:order_params) do
              order_json.tap do |o|
                o['operations_attributes'] = order.operations.as_json
                o['operations_attributes'].first['shift'] = -3
              end
            end

            include_examples 'updating order'

            it 'sets a new shift value' do
              expect { subject.run }.to change { changed_op.reload.shift }.by(-1)
            end

            it 'changes count_reserved' do
              subject.run

              expect(item_of_changed_op.reload.count_reserved).to eq 3
            end
          end
        end

        context 'and when added a new operations' do
          let!(:flash_items) { create(:new_item, warehouse_type: :without_invent_num, item_type: 'Флэш-накопитель', item_model: 'Silicon Power', count: 10, count_reserved: 0) }
          let(:new_operation) { attributes_for(:order_operation, item_id: flash_items.id, item_type: 'Флэш-накопитель', item_model: 'Silicon Power', shift: -1) }
          let(:order_params) do
            order_json['operations_attributes'] = order.operations.as_json
            order_json['operations_attributes'] << new_operation.as_json

            order_json
          end

          include_examples 'updating :out order'

          it 'creates added operations' do
            expect { subject.run }.to change(Operation, :count).by(1)
          end

          it 'changes :count_reserved attribute of item which belongs to created operation' do
            subject.run
            expect(flash_items.reload.count_reserved).to eq new_operation[:shift].abs
          end

          context 'and when order is not updated' do
            before do
              allow(Order).to receive_message_chain(:includes, :find).and_return(order)
              allow(order).to receive(:save).and_return(false)
            end

            include_examples 'failed updating :out without_invent_num'
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
          let!(:item_of_destroyed_operation) { order.operations.first.item }

          include_examples 'updating :out order'

          it 'destroys removed operations' do
            expect { subject.run }.to change(Operation, :count).by(-1)
          end

          it 'changes :count_reserved attribute of item which belongs to created operation' do
            subject.run
            expect(item_of_destroyed_operation.reload.count_reserved).to be_zero
          end
        end

        context 'and when have item for assign barcode' do
          let!(:item) { create(:new_item, warehouse_type: :without_invent_num, item_type: 'Картридж', item_model: '6515DNI', count: 2, count_reserved: 0) }
          let(:new_operation) { attributes_for(:order_operation, item_id: item.id, item_type: 'Картридж', item_model: '6515DNI', shift: -1) }
          let(:order_params) do
            order_json['operations_attributes'] = order.operations.as_json
            order_json['operations_attributes'] << new_operation.as_json

            order_json
          end

          it 'not changed count Operation in order' do
            expect { subject.run }.not_to change(Operation, :count)
          end
        end
      end

      context 'when warehouse_type is :with_invent_num' do
        let(:workplace) { create(:workplace_pk, disabled_filters: true) }
        let(:operation_1) { attributes_for(:order_operation, item_id: pc_items.id, shift: -2) }
        let(:operation_2) { attributes_for(:order_operation, item_id: monitor_items.id, shift: -2) }
        let(:operation_3) { attributes_for(:order_operation, item_id: mfu_items.id, shift: -1) }
        let(:create_order_params) do
          order = attributes_for(:order, operation: :out, invent_workplace_id: workplace.workplace_id, consumer_dept: workplace.workplace_count.division)
          order[:operations_attributes] = [operation_1, operation_2, operation_3]
          order
        end
        let(:order) { Order.last }
        let(:order_json) { order.as_json }
        let(:execute_order_params) do
          edit = Edit.new(order.id)
          edit.run
          edit.data[:order]['consumer_tn'] = user.tn
          edit.data[:order]['operations_attributes'].each_with_index do |op, index|
            if index == 1
              op['status'] = 'done'

              op['inv_items_attributes'] = Invent::Item.where(type: mon_type).map do |inv_item|
                {
                  id: inv_item.item_id,
                  serial_num: '111111'
                }
              end
            end

            op.delete('item')
            op.delete('inv_items')
            op.delete('inv_item_ids')
            op.delete('formatted_date')
            op.delete('invent_num_order')
            op.delete('operations_warehouse_receiver')
          end

          edit.data[:order].delete('fio_employee')
          edit.data[:order].delete('consumer')
          edit.data[:order].delete('attachment_order')
          edit.data[:order].delete('valid_op_warehouse_receiver_fio')
          edit.data[:order]
        end

        before do
          CreateOut.new(user, create_order_params.as_json).run
          ExecuteOut.new(user, order.id, execute_order_params.as_json).run
          order.reload
        end

        context 'and when increased :shift attribute' do
          let(:changed_op) { order.operations.first }
          let(:item_of_changed_op) { changed_op.item }
          let(:order_params) do
            order_json.tap do |o|
              o['operations_attributes'] = order.operations.as_json
              o['operations_attributes'].first['shift'] = -1
            end
          end

          it 'broadcasts to items' do
            expect(subject).to receive(:broadcast_items)
            subject.run
          end

          it 'broadcasts to out_orders' do
            expect(subject).to receive(:broadcast_out_orders)
            subject.run
          end

          include_examples 'updating order'

          its(:run) { is_expected.to be_truthy }

          # it 'sets a new validator data' do
          #   subject.run
          #   expect(order.reload.validator_id_tn).to eq new_user.id_tn
          #   expect(order.reload.validator_fio).to eq new_user.fullname
          # end

          it 'sets a new shift value' do
            expect { subject.run }.to change { changed_op.reload.shift }.by(1)
          end

          it 'changes count_reserved' do
            subject.run

            expect(item_of_changed_op.reload.count_reserved).to eq 1
          end

          it 'destroys inv_items record' do
            expect { subject.run }.to change(Invent::Item, :count).by(-1)
          end

          it 'destroyes inv_item_to_operations record' do
            expect { subject.run }.to change(InvItemToOperation, :count).by(-1)
          end
        end

        context 'and when reduced :shift attribute' do
          let(:changed_op) { order.operations.first }
          let(:item_of_changed_op) { changed_op.item }
          let(:order_params) do
            order_json.tap do |o|
              o['operations_attributes'] = order.operations.as_json
              o['operations_attributes'].first['shift'] = -4
            end
          end

          include_examples 'updating order'

          it 'sets a new shift value' do
            expect { subject.run }.to change { changed_op.reload.shift }.by(-2)
          end

          it 'changes count_reserved' do
            subject.run

            expect(item_of_changed_op.reload.count_reserved).to eq 4
          end

          it 'creates inv_items record' do
            expect { subject.run }.to change(Invent::Item, :count).by(2)
          end

          it 'creates inv_item_to_operations record' do
            expect { subject.run }.to change(InvItemToOperation, :count).by(2)
          end
        end

        context 'and when added a new operations (with item, which without invent_item_id)' do
          let(:printer_type) { Invent::Type.find_by(name: :printer) }
          let!(:printer_items) { create(:new_item, inv_type: printer_type, inv_model: printer_type.models.first, count: 25) }
          let(:new_operation) { attributes_for(:order_operation, item_id: printer_items.id, shift: -2) }
          let(:order_params) do
            order_json['operations_attributes'] = order.operations.as_json
            order_json['operations_attributes'] << new_operation.as_json

            order_json
          end

          include_examples 'updating :out order'

          it 'creates added operations' do
            expect { subject.run }.to change(Operation, :count).by(1)
          end

          it 'creates new inv_items record' do
            expect { subject.run }.to change(Invent::Item, :count).by(2)
          end

          it 'sets workplace_id to the inv_item' do
            subject.run
            expect(Invent::Item.find_by(type: printer_type).workplace_id).to eq order.invent_workplace_id
          end

          it 'sets :waiting_take status of inv_item' do
            subject.run
            expect(Invent::Item.find_by(type: printer_type).status).to eq 'waiting_take'
          end

          it 'creates new inv_item_to_operations record' do
            expect { subject.run }.to change(InvItemToOperation, :count).by(2)
          end

          it 'changes :count_reserved attribute of item which belongs to created operation' do
            subject.run
            expect(printer_items.reload.count_reserved).to eq new_operation[:shift].abs
          end

          context 'and when order is not updated' do
            before do
              allow(Order).to receive_message_chain(:includes, :find).and_return(order)
              allow(order).to receive(:save).and_return(false)
            end

            include_examples 'failed updating :out on add'
          end

          context 'and when Invent::Item is not saved' do
            before { allow_any_instance_of(Invent::Item).to receive(:save).and_return(false) }

            include_examples 'failed updating :out on add'
          end
        end

        context 'and when added a new operations (with item, which with invent_item_id)' do
          let(:printer_type) { Invent::Type.find_by(name: :printer) }
          let(:printer_inv_item) { create(:item, :with_property_values, type_name: :printer) }
          let!(:printer_items) { create(:used_item, inv_item: printer_inv_item, count: 1) }
          let(:new_operation) { attributes_for(:order_operation, item_id: printer_items.id, shift: -1) }
          let(:order_params) do
            order_json['operations_attributes'] = order.operations.as_json
            order_json['operations_attributes'] << new_operation.as_json

            order_json
          end

          include_examples 'updating :out order'

          it 'creates added operations' do
            expect { subject.run }.to change(Operation, :count).by(1)
          end

          it 'does not create new inv_items record' do
            expect { subject.run }.not_to change(Invent::Item, :count)
          end

          it 'creates new inv_item_to_operations record' do
            expect { subject.run }.to change(InvItemToOperation, :count).by(1)
          end

          it 'associate inv_item with created operation' do
            subject.run
            expect(InvItemToOperation.last.invent_item_id).to eq printer_inv_item.item_id
          end

          it 'sets workplace_id to the inv_item' do
            subject.run
            expect(printer_inv_item.reload.workplace_id).to eq order.invent_workplace_id
          end

          it 'sets :waiting_take status of inv_item' do
            subject.run
            expect(printer_inv_item.reload.status).to eq 'waiting_take'
          end

          it 'changes :count_reserved attribute of item which belongs to created operation' do
            subject.run
            expect(printer_items.reload.count_reserved).to eq new_operation[:shift].abs
          end
        end

        context 'and when remove processing operation (with item, which without invent_item_id)' do
          let(:order_params) do
            order_json['operations_attributes'] = order.operations.as_json
            order_json['operations_attributes'].each_with_index do |op, index|
              op['_destroy'] = 1 if index.zero?
            end

            order_json
          end

          include_examples 'updating :out order'

          it 'destroys removed operations' do
            expect { subject.run }.to change(Operation, :count).by(-1)
          end

          it 'destroys inv_items record' do
            expect { subject.run }.to change(Invent::Item, :count).by(-2)
          end

          it 'destroys inv_item_to_operations record' do
            expect { subject.run }.to change(InvItemToOperation, :count).by(-2)
          end

          it 'destroys invent_items associated with removed operation' do
            subject.run
            expect(Invent::Item.where(type: pc_type)).to be_empty
          end

          it 'changes :count_reserved attribute of item' do
            subject.run
            expect(pc_items.reload.count_reserved).to be_zero
          end

          context 'and when order is not updated' do
            before do
              allow(Order).to receive_message_chain(:includes, :find).and_return(order)
              allow(order).to receive(:save).and_return(false)
            end

            include_examples 'failed updating :out on del'
          end

          context 'and when Invent::Item is not destroyed' do
            before { allow_any_instance_of(Invent::Item).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed) }

            include_examples 'failed updating :out on del'
          end

          context 'and when Item is not saved' do
            before { allow_any_instance_of(Item).to receive(:save!).and_raise(ActiveRecord::RecordNotSaved) }

            include_examples 'failed updating :out on del'
          end
        end

        context 'and when remove processing operation (with item, which with invent_item_id)' do
          let(:order_params) do
            order_json['operations_attributes'] = order.operations.as_json
            order_json['operations_attributes'].each_with_index do |op, index|
              op['_destroy'] = 1 if index == 2
            end

            order_json
          end

          include_examples 'updating :out order'

          it 'destroys removed operations' do
            expect { subject.run }.to change(Operation, :count).by(-1)
          end

          it 'does not destroy inv_items record' do
            expect { subject.run }.not_to change(Invent::Item, :count)
          end

          it 'destroys inv_item_to_operations record' do
            expect { subject.run }.to change(InvItemToOperation, :count).by(-1)
          end

          it 'sets nil to the :workplace attribute of inv_item which associated with destroyed operation' do
            subject.run
            expect(inv_mfu_item.reload.workplace_id).to be_nil
          end

          it 'changes :count_reserved attribute of item' do
            subject.run
            expect(mfu_items.reload.count_reserved).to be_zero
          end

          it 'sets workplace_id to the nil' do
            subject.run
            expect(inv_mfu_item.reload.workplace_id).to be_nil
          end

          it 'sets :in_stock status of inv_item' do
            subject.run
            expect(inv_mfu_item.reload.status).to eq 'in_stock'
          end
        end

        context 'and when remove done operation' do
          let(:order_params) do
            order_json['operations_attributes'] = order.operations.as_json
            order_json['operations_attributes'].each_with_index do |op, index|
              op['_destroy'] = 1 if index == 1
            end

            order_json
          end

          include_examples 'failed updating :out on del'
        end

        context 'and when change shift for done operation' do
          let(:order_params) do
            order_json['operations_attributes'] = order.operations.as_json
            order_json['operations_attributes'].each_with_index do |op, index|
              op['shift'] = -17 if index == 1
            end

            order_json
          end

          include_examples 'failed updating :out on del'
        end
      end
    end
  end
end
