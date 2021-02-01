require 'feature_helper'

module Warehouse
  module Orders
    RSpec.describe ExecuteIn, type: :model do
      let!(:current_user) { create(:***REMOVED***_user) }
      subject { ExecuteIn.new(current_user, order.id, order_params) }

      before { allow(UnregistrationWorker).to receive(:perform_async).and_return(true) }

      context 'when operations belongs_to item' do
        let(:first_inv_item) { create(:item, :with_property_values, type_name: :pc, status: :waiting_bring, priority: :high) }
        let(:sec_inv_item) { create(:item, :with_property_values, type_name: :monitor, priority: :high) }
        let(:workplace) do
          wp = build(:workplace_pk, items: [first_inv_item, sec_inv_item], dept: ***REMOVED***)
          wp.save(validate: false)
          wp
        end
        let(:first_item) { create(:used_item, inv_item: first_inv_item, count: 0, count_reserved: 0) }
        let(:sec_item) { create(:used_item, inv_item: sec_inv_item, count: 0, count_reserved: 0) }
        let(:operations) do
          [
            build(:order_operation, item: first_item, inv_items: [first_inv_item]),
            build(:order_operation, item: sec_item, inv_items: [sec_inv_item])
          ]
        end
        let!(:order) { create(:order, inv_workplace: workplace, operations: operations) }
        let(:order_json) { order.as_json }
        let(:order_params) do
          order_json['consumer_tn'] = ***REMOVED***
          order_json['operations_attributes'] = operations.as_json
          order_json['operations_attributes'].each_with_index do |op, index|
            op['status'] = 'done' if index.zero?
          end

          order_json
        end

        it 'broadcasts to in_orders' do
          expect(subject).to receive(:broadcast_in_orders)
          subject.run
        end

        it 'broadcasts to archive_orders' do
          expect(subject).to receive(:broadcast_archive_orders)
          subject.run
        end

        it 'broadcasts to items' do
          expect(subject).to receive(:broadcast_items)
          subject.run
        end

        it 'broadcasts to workplaces' do
          expect(subject).to receive(:broadcast_workplaces)
          subject.run
        end

        context 'and when :operation attribute changes to :out' do
          before { order_params['operation'] = 'out' }

          include_examples 'order error format'
        end

        context 'and when :shift attribute changes to negative value' do
          before { order_params['operations_attributes'].first['shift'] = -4 }

          include_examples 'order error format'
        end

        include_examples 'execute_in specs'

        it 'changes count of warehouse_items' do
          expect { subject.run }.to change { Item.first.count }.by(operations.first.shift)
        end

        it 'runs :to_stock! method' do
          expect_any_instance_of(Invent::Item).to receive(:to_stock!)

          subject.run
        end

        it 'does not run Orders::CreateWriteOff service' do
          expect(Orders::CreateWriteOff).not_to receive(:new)

          subject.run
        end

        it 'does not broadcast to write_off_orders' do
          expect(subject).not_to receive(:broadcast_write_off_orders)

          subject.run
        end

        # it 'sets nil to the workplace, :in_stock to the status and :default to the priority attributes into the invent_item record' do
        #   subject.run
        #
        #   expect(first_inv_item.reload.workplace).to be_nil
        #   expect(first_inv_item.reload.status).to eq 'in_stock'
        #   expect(first_inv_item.reload.priority).to eq 'default'
        # end

        it 'does not set nil to the workplace into another invent_item records' do
          subject.run

          expect(sec_inv_item.reload.workplace).to eq workplace
        end

        context 'and when invent_item was not updated' do
          before { allow_any_instance_of(Invent::Item).to receive(:update!).and_raise(ActiveRecord::RecordNotSaved) }

          it 'does not save all another records' do
            subject.run

            expect(operations.first.reload.processing?).to be_truthy
            expect(operations.first.reload.stockman_fio).to be_nil
            expect(operations.first.reload.stockman_id_tn).to be_nil
            expect(order.reload.consumer_id_tn).to be_nil
            expect(order.reload.consumer_fio).to be_nil
            expect(first_item.reload.count).to be_zero
          end
        end

        context 'and when warehouse_item was not updated' do
          before { allow_any_instance_of(Item).to receive(:save!).and_raise(ActiveRecord::RecordNotSaved) }

          it 'does not save all another records' do
            subject.run

            expect(operations.first.reload.processing?).to be_truthy
            expect(operations.first.reload.stockman_fio).to be_nil
            expect(operations.first.reload.stockman_id_tn).to be_nil
            expect(order.reload.consumer_id_tn).to be_nil
            expect(order.reload.consumer_fio).to be_nil
            expect(first_inv_item.reload.workplace).to eq workplace
          end
        end

        context 'and when order was not updated' do
          before do
            allow_any_instance_of(Order).to receive(:save).and_return(false)
            subject.run
          end

          it 'does not save all another records' do
            expect(operations.first.reload.processing?).to be_truthy
            expect(operations.first.reload.stockman_fio).to be_nil
            expect(operations.first.reload.stockman_id_tn).to be_nil
            expect(first_inv_item.reload.workplace).to eq workplace
            expect(first_item.reload.count).to be_zero
          end

          it 'adds fill error object with %i[object full_message] keys' do
            expect(subject.error).to include(:object, :full_message)
          end
        end

        context 'and when operations is not selected' do
          let(:order_params) do
            order_json['consumer_tn'] = ***REMOVED***
            order_json['operations_attributes'] = operations.as_json
            order_json
          end

          it 'adds :operation_not_selected error' do
            subject.run

            expect(subject.error[:full_message]).to eq 'Необходимо выбрать хотя бы одну позицию'
          end

          context 'and when operation has :to_write_off flag' do
            let(:order_params) do
              order_json['consumer_tn'] = ***REMOVED***
              order_json['operations_attributes'] = operations.as_json
              order_json['operations_attributes'].each_with_index do |op, index|
                next unless index.zero?

                op['to_write_off'] = true
              end

              order_json
            end

            it 'does not run Orders::CreateWriteOff service' do
              expect(Orders::CreateWriteOff).not_to receive(:new)

              subject.run
            end

            it 'does not broadcast to write_off_orders' do
              expect(subject).not_to receive(:broadcast_write_off_orders)

              subject.run
            end

            its(:run) { is_expected.to be_falsey }
          end
        end

        context 'and when operation has :to_write_off flag' do
          let(:order_params) do
            order_json['consumer_tn'] = ***REMOVED***
            order_json['operations_attributes'] = operations.as_json
            order_json['operations_attributes'].each_with_index do |op, index|
              next unless index.zero?

              op['status'] = 'done'
              op['to_write_off'] = true
            end

            order_json
          end
          let(:write_off) { Orders::CreateWriteOff.new(current_user, order_params) }
          let(:create_write_off) { double(:create_write_off) }

          it 'runs Orders::CreateWriteOff service' do
            allow(Orders::CreateWriteOff).to receive(:new).and_return(create_write_off)
            expect(write_off).to receive(:run).and_return(true)

            subject.run
          end

          it 'creates order with :write_off operation' do
            subject.run

            expect(Order.last.operation).to eq 'write_off'
          end

          it 'broadcasts to write_off_orders' do
            expect(subject).to receive(:broadcast_write_off_orders)

            subject.run
          end

          its(:run) { is_expected.to be_truthy }
        end
      end

      context 'and when operations is not belong to item' do
        let(:first_op) { build(:order_operation, item_model: 'Мышь', item_type: 'Logitech') }
        let(:sec_op) { build(:order_operation, item_model: 'Клавиатура', item_type: 'OKLICK') }
        let(:operations) { [first_op, sec_op] }
        let!(:order) { create(:order, operations: operations) }
        let(:order_json) { order.as_json }
        let(:order_params) do
          order_json['consumer_tn'] = ***REMOVED***
          order_json['operations_attributes'] = operations.as_json
          order_json['operations_attributes'].each do |op|
            op['status'] = 'done'
          end
          order_json
        end

        include_examples 'execute_in specs'

        it 'creates a new warehouse_item' do
          expect { subject.run }.to change(Item, :count).by(2)
        end

        it 'sets warehouse_item values from a corresponding operations' do
          subject.run

          [first_op, sec_op].each do |op|
            op.reload
            expect(op.item.warehouse_type).to eq 'without_invent_num'
            expect(op.item.item_type).to eq op.item_type
            expect(op.item.item_model).to eq op.item_model
            expect(op.item.status).to eq 'used'
            expect(op.item.count).to eq op.shift
            expect(op.item.count_reserved).to be_zero
          end
        end

        context 'and when warehouse_item was not created' do
          before { allow_any_instance_of(Operation).to receive(:create_item!).and_raise { ActiveRecord::RecordNotSaved } }

          it 'does not save all another records' do
            subject.run

            [first_op.reload, sec_op.reload].each do |op|
              expect(op.processing?).to be_truthy
              expect(op.stockman_fio).to be_nil
              expect(op.stockman_id_tn).to be_nil
            end
            expect(order.reload.consumer_id_tn).to be_nil
            expect(order.reload.consumer_fio).to be_nil
          end

          it 'does not create item' do
            expect { subject.run }.not_to change(Item, :count)
          end

          its(:run) { is_expected.to be_falsey }
        end

        context 'and when order was not updated' do
          before { allow_any_instance_of(Order).to receive(:save).and_return(false) }

          it 'does not save all another records' do
            subject.run

            [first_op, sec_op].each do |op|
              expect(op.reload.processing?).to be_truthy
              expect(op.reload.stockman_fio).to be_nil
              expect(op.reload.stockman_id_tn).to be_nil
            end
          end

          it 'does not create item' do
            expect { subject.run }.not_to change(Item, :count)
          end

          its(:run) { is_expected.to be_falsey }
        end

        context 'and when in operations contain warehouse_item with barcode' do
          let(:inv_item) { create(:item, :with_property_values, type_name: :printer) }
          let(:property_with_barcode) { Invent::Property.find_by(short_description: Invent::Property::LIST_TYPE_FOR_BARCODES.first.capitalize) }
          let(:inv_property_value) { create(:property_value, property: property_with_barcode, item: inv_item) }
          let(:warehouse_item) do
            w_item = build(:new_item, warehouse_type: :without_invent_num, item_type: 'картридж', item_model: '6515DNI', count: 0)
            w_item.build_barcode_item
            w_item.invent_property_value = inv_property_value

            w_item.save(validate: false)
            w_item
          end
          let(:third_op) { build(:order_operation, item_model: warehouse_item.item_type, item_type: warehouse_item.item_model, item: warehouse_item) }
          let(:operations) { [first_op, sec_op, third_op] }

          it 'deleted invent_property_value' do
            expect { subject.run }.to change(Invent::PropertyValue, :count).by(-1)
          end

          it 'sets status and count for warehouse_item' do
            expect { subject.run }
              .to change { warehouse_item.reload.status }.from('non_used').to('used')
                    .and change { warehouse_item.reload.count }.from(0).to(1)
          end
        end
      end

      context 'and when one of operations already done and another just selected' do
        let(:user) { create(:user) }
        let(:item) { create(:used_item, warehouse_type: :without_invent_num, item_type: 'Мышь', item_model: 'Logitech') }
        let(:first_op) { build(:order_operation, item_type: 'Мышь', item_model: 'Logitech', status: :done, item: item, stockman_id_tn: user.id_tn) }
        let(:sec_op) { build(:order_operation, item_type: 'Клавиатура', item_model: 'OKLICK') }
        let(:operations) { [first_op, sec_op] }
        let!(:order) { create(:order, inv_workplace: nil, operations: operations, consumer_tn: user.tn) }
        let(:order_json) { order.as_json }
        let(:order_params) do
          order_json['consumer_tn'] = ***REMOVED***
          order_json['operations_attributes'] = operations.as_json
          order_json['operations_attributes'].each do |op|
            op['status'] = 'done'
          end
          order_json
        end

        its(:run) { is_expected.to be_truthy }
      end
    end
  end
end
