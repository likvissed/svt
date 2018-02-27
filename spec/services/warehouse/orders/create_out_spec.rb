require 'feature_helper'

module Warehouse
  module Orders
    RSpec.describe CreateOut, type: :model do
      let!(:current_user) { create(:***REMOVED***_user) }
      let!(:workplace) do
        wp = build(:workplace_pk, dept: ***REMOVED***)
        wp.save(validate: false)
        wp
      end
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

        its(:run) { is_expected.to be_truthy }

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
        let(:operation_1) { attributes_for(:order_operation, item_id: item_1.id, shift: -1) }
        let(:operation_2) { attributes_for(:order_operation, item_id: item_2.id, shift: -1) }
        let(:operation_3) { attributes_for(:order_operation, item_id: item_3.id, shift: -1) }
        let(:operation_4) { attributes_for(:order_operation, item_id: item_4.id, shift: -1) }
        let(:operation_5) { attributes_for(:order_operation, item_id: item_5.id, shift: -2) }
        let(:order_params) do
          order = attributes_for(:order, operation: :out, invent_workplace_id: workplace.workplace_id)
          order[:operations_attributes] = [operation_1, operation_2, operation_3, operation_4, operation_5]
          order
        end

        its(:run) { is_expected.to be_truthy }

        it 'creates warehouse_operations records' do
          expect { subject.run }.to change(Operation, :count).by(order_params[:operations_attributes].size)
        end

        it 'creates warehouse_item_to_orders records' do
          expect { subject.run }.to change(InvItemToOperation, :count).by(5)
        end

        it 'creates invent_items records' do
          expect { subject.run }.to change(Invent::Item, :count).by(4)
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

        context 'and when model exists' do
          let(:type) { Invent::Type.find_by(name: :monitor) }
          let(:pc_properties) { type.properties }
          let(:prop) { pc_properties.find_by(property_type: %w[list list_plus]) }
          let(:item) { Invent::Item.where(invent_num: nil).where('model_id IS NOT NULL').find_by(type: type) }
``
          it 'creates property_values' do
            subject.run
            expect(Invent::Item.find_by(type: type).property_values.size).to eq pc_properties.size
          end

          it 'fills property_values from the invent_model_property_list table' do
            subject.run
            expect(item.property_values.find_by(property: prop).property_list).to eq item.model.model_property_lists.find_by(property: prop).property_list
          end
        end

        it 'creates order' do
          expect { subject.run }.to change(Order, :count).by(1)
        end

        it 'sets :count_reserved attribute of the each item (except last) to 1' do
          subject.run
          [item_1, item_2, item_3, item_4].each { |item| expect(item.reload.count_reserved).to eq 1 }
        end

        it 'sets :count_reserved attribute of last item to 2' do
          subject.run
          expect(item_5.reload.count_reserved).to eq 2
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
    end
  end
end
