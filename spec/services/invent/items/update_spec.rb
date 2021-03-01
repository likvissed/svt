require 'feature_helper'

module Invent
  module Items
    RSpec.describe Update, type: :model do
      let!(:user) { create(:user) }
      let(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
      let!(:old_item) { create(:item, :with_property_values, type_name: :monitor) }
      # let!(:w_item) { create(:used_item, inv_item: old_item, invent_num_end: 200) }
      let(:new_model) { Invent::Model.last }
      let(:new_item_model) { 'new_test_item_model' }
      let(:new_invent_num) { '199' }
      let(:property_with_assign_barcode) { Invent::Property.where(assign_barcode: true).pluck(:property_id) }
      let(:new_item) do
        edit = Edit.new(old_item.item_id)
        edit.run

        data = edit.data[:item]
        data['invent_num'] = new_invent_num
        # data['model_id'] = new_model.model_id
        data['model_id'] = nil
        # data['item_model'] = new_model.item_model
        data['item_model'] = new_item_model
        data['property_values_attributes'].each do |prop_val|
          prop_val['property_list_id'] = 15

          prop_val['value'] = '' if property_with_assign_barcode.include?(prop_val['property_id'])

          prop_val.delete('property_list')
        end
        data.delete('full_item_model')

        data.as_json
      end
      # let(:operation) { attributes_for(:order_operation, item_id: old_item.id, shift: -1) }
      # let(:processing_operation) { w_item.operations.find_by(status: :processing) }
      # let!(:done_operation) { create(:order_operation, inv_item_ids: [old_item.item_id], item: w_item, stockman_fio: user.fullname, stockman_id_tn: user.id_tn, status: :done) }
      # before do
      #   order_params = attributes_for(:order, operation: :out, invent_workplace_id: workplace.workplace_id)
      #   order_params[:operations_attributes] = [operation]
      #   Warehouse::Orders::CreateOut.new(user, order_params.as_json).run
      # end
      subject { Items::Update.new(user, old_item.item_id, new_item) }

      context 'with valid item params' do
        its(:run) { is_expected.to be_truthy }

        it 'updates item data' do
          subject.run

          expect(old_item.reload.invent_num).to eq new_invent_num
          expect(old_item.reload.property_values.first.property_list_id).to eq 15
          # expect(old_item.reload.model_id).to eq new_model.model_id
          expect(old_item.reload.model).to be_nil
          expect(old_item.reload.item_model).to eq new_item_model
        end

        it 'broadcasts to items' do
          expect(subject).to receive(:broadcast_items)

          subject.run
        end

        it 'broadcasts to workplaces_list' do
          expect(subject).to receive(:broadcast_workplaces_list)

          subject.run
        end

        context 'and when warehouse_item does not exist' do
          before { allow_any_instance_of(Invent::Item).to receive(:warehouse_item).and_return(nil) }

          its(:run) { is_expected.to be_truthy }
        end

        context 'and when assign barcode in the property is true' do
          let!(:old_item) { create(:item, :with_property_values, type_name: :printer) }
          it 'property value not changed for assign barcode' do
            sent_property_value = new_item['property_values_attributes'].find do |prop_val|
              property_with_assign_barcode.include?(prop_val['property_id'])
            end

            subject.run

            changed_prop_value = old_item.reload.property_values.find do |prop_val|
              property_with_assign_barcode.include?(prop_val['property_id'])
            end

            expect(changed_prop_value.value).not_to eq sent_property_value['value']
          end
        end
      end

      context 'with invalid item params' do
        before { allow_any_instance_of(Item).to receive(:update).and_return(false) }

        its(:run) { is_expected.to be_falsey }

        it 'does not update item data' do
          expect { subject.run }.not_to change { old_item.reload.invent_num }
        end

        it 'does not broadcast to items' do
          expect(subject).not_to receive(:broadcast_items)

          subject.run
        end

        it 'does not broadcast to workplaces_list' do
          expect(subject).not_to receive(:broadcast_workplaces_list)

          subject.run
        end
      end
    end
  end
end
