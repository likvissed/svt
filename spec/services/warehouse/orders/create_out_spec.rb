require 'feature_helper'

module Warehouse
  module Orders
    RSpec.describe CreateOut, type: :model do
      skip_users_reference

      let!(:current_user) { create(:***REMOVED***_user) }
      let!(:workplace) do
        wp = build(:workplace_pk, dept: ***REMOVED***)
        wp.save(validate: false)
        wp
      end
      before { allow_any_instance_of(Order).to receive(:find_employee_by_workplace).and_return([build(:emp_***REMOVED***)]) }
      subject { CreateOut.new(current_user, order_params.as_json) }

      context 'when item was not selected' do
        let(:order_params) do
          order = attributes_for(:order, operation: :out, invent_workplace_id: workplace.workplace_id)
          order[:operations_attributes] = []
          order
        end

        its(:run) { is_expected.to be_falsey }
      end

      context 'when item is used' do
        let(:pc) { create(:item, :with_property_values, type_name: 'pc') }
        let!(:item_1) { create(:used_item, count: 1) }
        let!(:item_2) { create(:used_item, inv_item: pc, count: 1) }
        let!(:item_3) { create(:used_item, warehouse_type: :without_invent_num, item_type: 'Клавиатура', item_model: 'OKLICK', count: 1) }
        let(:operation_1) { attributes_for(:order_operation, item_id: item_1.id, shift: -1) }
        let(:operation_2) { attributes_for(:order_operation, item_id: item_2.id, shift: -1) }
        let(:operation_3) { attributes_for(:order_operation, item_id: item_3.id, shift: -1) }
        let(:order_params) do
          order = attributes_for(:order, operation: :out, invent_workplace_id: workplace.workplace_id)
          order[:operations_attributes] = [operation_1, operation_2, operation_3]
          order
        end
        let(:inv_items) { Item.includes(:inv_item).find(order_params[:operations_attributes].map { |op| op[:item_id] }).map(&:inv_item).compact }
        let(:items) { Item.find(order_params[:operations_attributes].map { |op| op[:item_id] }) }

        context 'and when :operation attribute is not :out' do
          before { order_params['operation'] = 'in' }

          its(:run) { is_expected.to be_falsey }
        end

        context 'and when :shift attribute of any operation has positive value' do
          before { order_params[:operations_attributes].first[:shift] = 1 }

          it 'exit from service without processing params' do
            expect(subject).not_to receive(:init_order)
            subject.run
          end

          its(:run) { is_expected.to be_falsey }
        end

        its(:run) { is_expected.to be_truthy }

        it 'sets validator fields' do
          subject.run

          expect(Order.last.validator_id_tn).to eq current_user.id_tn
          expect(Order.last.validator_fio).to eq current_user.fullname
        end

        it 'creates warehouse_operations records' do
          expect { subject.run }.to change(Operation, :count).by(order_params[:operations_attributes].size)
        end

        it 'creates warehouse_item_to_orders records' do
          expect { subject.run }.to change(InvItemToOperation, :count).by(2)
        end

        it 'creates order' do
          expect { subject.run }.to change(Order, :count).by(1)
        end

        it 'changes :count_reserved of the each item' do
          subject.run
          items.each { |item| expect(item.count_reserved).to eq 1 }
        end

        it 'does not create inv_item' do
          expect { subject.run }.not_to change(Invent::Item, :count)
        end

        it 'changes status to :waiting_take and sets workplace in the each selected item' do
          subject.run

          inv_items.each do |item|
            expect(item.status).to eq 'waiting_take'
            expect(item.workplace_id).to eq workplace.workplace_id
          end
        end

        context 'and when order was not created' do
          let(:order) { build(:order, :without_operations, operation: :out, invent_workplace_id: workplace.workplace_id) }
          before do
            allow(Order).to receive(:new).and_return(order)
            allow(order).to receive(:save).and_return(false)
          end

          include_examples 'failed creating :out models'
        end

        include_examples 'specs for failed on create :out order'
      end

      context 'when item is not used' do
        let(:monitor) { create(:item, :with_property_values, type_name: 'monitor') }
        let!(:item_1) { create(:new_item, inv_type: Invent::Type.find_by(name: :pc), item_type: 'Системный блок', item_model: 'UNIT', count: 2) }
        let!(:item_2) { create(:new_item, inv_type: Invent::Type.find_by(name: :monitor), item_type: 'Монитор', item_model: 'SAMSUNG NEW MODEL', count: 2) }
        let!(:item_3) { create(:new_item, warehouse_type: :without_invent_num, item_type: 'Мышь', item_model: 'ASUS', count: 2) }
        let!(:item_4) { create(:used_item, inv_item: monitor, count: 1) }
        let!(:item_5) { create(:new_item, inv_type: Invent::Type.find_by(name: :monitor), inv_model: Invent::Type.find_by(name: :monitor).models.first, count: 2) }
        let!(:item_6) { create(:new_item, inv_type: Invent::Type.find_by(name: :mfu), inv_model: Invent::Type.find_by(name: :mfu).models.first, count: 2) }
        let(:operation_1) { attributes_for(:order_operation, item_id: item_1.id, shift: -1) }
        let(:operation_2) { attributes_for(:order_operation, item_id: item_2.id, shift: -1) }
        let(:operation_3) { attributes_for(:order_operation, item_id: item_3.id, shift: -1) }
        let(:operation_4) { attributes_for(:order_operation, item_id: item_4.id, shift: -1) }
        let(:operation_5) { attributes_for(:order_operation, item_id: item_5.id, shift: -2) }
        let(:operation_6) { attributes_for(:order_operation, item_id: item_6.id, shift: -1) }
        let(:order_params) do
          order = attributes_for(:order, operation: :out, invent_workplace_id: workplace.workplace_id)
          order[:operations_attributes] = [operation_1, operation_2, operation_3, operation_4, operation_5, operation_6]
          order
        end

        its(:run) { is_expected.to be_truthy }

        it 'sets validator fields' do
          subject.run

          expect(Order.last.validator_id_tn).to eq current_user.id_tn
          expect(Order.last.validator_fio).to eq current_user.fullname
        end

        it 'creates warehouse_operations records' do
          expect { subject.run }.to change(Operation, :count).by(order_params[:operations_attributes].size)
        end

        it 'creates warehouse_item_to_orders records' do
          expect { subject.run }.to change(InvItemToOperation, :count).by(6)
        end

        it 'creates invent_items records' do
          expect { subject.run }.to change(Invent::Item, :count).by(5)
        end

        context 'and when model does not exist' do
          let(:type) { Invent::Type.find_by(name: :pc) }
          let(:pc_properties) { type.properties }

          it 'creates property_values' do
            subject.run
            expect(Invent::Item.find_by(type: type).property_values.size).to eq pc_properties.size
          end

          it 'fills property_values with empty values' do
            subject.run
            Invent::Item.find_by(type: type).property_values.each do |prop_val|
              expect(prop_val.value).to be_empty
              expect(prop_val.property_list).to be_nil
            end
          end
        end

        it 'creates order' do
          expect { subject.run }.to change(Order, :count).by(1)
        end

        it 'sets :count_reserved attribute of the each item (except last) to 1' do
          subject.run
          [item_1, item_2, item_3, item_4, item_6].each { |item| expect(item.reload.count_reserved).to eq 1 }
        end

        it 'sets :count_reserved attribute of last item to 2' do
          subject.run
          expect(item_5.reload.count_reserved).to eq 2
        end

        it 'broadcasts to out_orders' do
          expect(subject).to receive(:broadcast_out_orders)
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

        it 'broadcasts to workplaces_list' do
          expect(subject).to receive(:broadcast_workplaces_list)
          subject.run
        end

        context 'and when order was not created' do
          before { allow_any_instance_of(Order).to receive(:save).and_return(false) }

          its(:run) { is_expected.to be_falsey }

          [Invent::Item, Order, Item, InvItemToOperation, Operation].each do |klass|
            it "does not create #{klass.name} record" do
              expect { subject.run }.not_to change(klass, :count)
            end
          end

          it 'does not change status and workpalce_id of Invent::Item model' do
            subject.run

            Invent::Item.find_each do |item|
              expect(item.status).to be_nil
              expect(item.workplace_id).to be_nil
            end
          end

          it 'does not changes :count_reserved of selected items' do
            subject.run

            Item.find_each { |item| expect(item.count_reserved).to be_zero }
          end
        end

        include_examples 'specs for failed on create :out order'
      end

      context 'when have item for assign barcode' do
        let!(:inv_item) { create(:item, :with_property_values, type_name: :printer, status: :in_workplace) }
        let(:workplace) do
          w = build(:workplace_net_print, items: [inv_item])
          w.save(validate: false)
          w
        end

        let(:item) { create(:used_item, warehouse_type: :without_invent_num, item_type: 'Картридж', item_model: '6515DNI', count: 1) }
        let(:operation) { attributes_for(:order_operation, item_id: item.id, shift: -1) }

        let(:order_params) do
          order = attributes_for(:order, operation: :out, invent_workplace_id: workplace.workplace_id, invent_num: workplace.items.first.invent_num)
          order[:operations_attributes] = [operation]
          order
        end

        it { is_expected.to be_valid }

        it 'order :out is created' do
          expect { subject.run }.to change(Order, :count)
        end

        context 'and when invent_num for order incorrect' do
          before { order_params[:invent_num] = order_params[:invent_num].to_i + 1 }

          it 'order :out is not created' do
            expect { subject.run }.not_to change(Order, :count)
          end
        end
      end

      context 'when add request_id for order' do
        let(:request) { create(:request_category_one, executor_tn: current_user.tn, status: :analysis) }
        let!(:inv_item) { create(:item, :with_property_values, type_name: :printer, status: :in_workplace) }
        let(:workplace) do
          w = build(:workplace_net_print, items: [inv_item])
          w.save(validate: false)
          w
        end
        let(:item) { create(:used_item, warehouse_type: :without_invent_num, item_type: 'Картридж', item_model: '6515DNI', count: 1) }
        let(:operation) { attributes_for(:order_operation, item_id: item.id, shift: -1) }
        let(:order_params) do
          order = attributes_for(:order, operation: :out, invent_workplace_id: workplace.workplace_id, request_id: request.request_id)
          order[:operations_attributes] = [operation]
          order
        end
        let(:order) { build(:order, :without_operations, operation: :out, invent_workplace_id: workplace.workplace_id) }
        before do
          order_params[:request_id] = request.request_id
          allow_any_instance_of(Order).to receive(:present_item_for_barcode).and_return(true)
          allow(Orbita).to receive(:add_event)
        end

        context 'and when role users is :worker' do
          let(:worker_role) { create(:worker_role) }
          before { current_user.role_id = worker_role.id }

          it 'change status from request' do
            subject.run

            expect(request.reload.status).to eq('check')
          end
        end

        context 'and when role users is :manager or :admin' do
          before { current_user.role = Role.find_by(name: :admin) }

          it 'change status from request' do
            subject.run

            expect(request.reload.status).to eq('waiting_confirmation_for_user')
          end
        end

        context 'and when category not :office_equipment' do
          let(:current_status) { 'analysis' }
          let(:request) { create(:request_category_two, status: current_status) }

          it 'status to request not changed' do
            subject.run

            expect(request.reload.status).to eq(current_status)
          end
        end

        context 'and when request not present' do
          before { order_params[:request_id] = 990_990 }

          its(:run) { is_expected.to be_falsey }
        end
      end
    end
  end
end
