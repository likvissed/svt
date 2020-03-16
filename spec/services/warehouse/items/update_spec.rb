require 'feature_helper'

module Warehouse
  module Items
    RSpec.describe Update, type: :model do
      describe '#run' do
        let(:property) { Invent::Property.all }
        let(:current_user) { create(:user) }
        let(:location) { create(:location) }

        let(:new_item) do
          edit = Edit.new(item.id)
          edit.run

          edit.data[:item][:property_values_attributes] = Array.wrap(param_property_value).as_json
          edit.data[:item][:property_values_attributes].each do |prop_val|
            prop_val['id'] = prop_val['warehouse_property_value_id']
            prop_val.delete('warehouse_property_value_id')
          end

          edit.data[:item]['location_attributes'] = location
          edit.data[:item].delete('location')
          edit.data[:item]['location_id'] = location.id

          item_params = edit.data[:item]
          item_params.as_json
        end

        subject { Update.new(current_user, item.id, new_item) }

        context 'when property_values for item present' do
          let!(:item) { create(:item_with_property_values, status: 'non_used') }

          its(:run) { is_expected.to be_truthy }

          include_examples 'add new property_value'
          include_examples 'property_value invalid'
          include_examples 'add a location in item'

          context 'and when properties updated' do
            let(:new_value) { 'P5QPL-AM' }
            let(:param_property_value) { item.property_values.find_by(property_id: property.find_by(name: 'mb').property_id) }
            before { param_property_value.value = new_value }

            it 'value property_value updated' do
              subject.run

              expect(PropertyValue.find(param_property_value[:warehouse_property_value_id]).value).to eq new_value
            end
          end

          context 'and when property deleted' do
            let(:param_property_value) { item.property_values.find_by(property_id: property.find_by(name: 'hdd').property_id).as_json }
            before { param_property_value['_destroy'] = 1 }

            it 'raises RecordNotFound error' do
              subject.run

              expect { PropertyValue.find(param_property_value['warehouse_property_value_id']) }.to raise_exception(ActiveRecord::RecordNotFound)
            end

            it 'decrease count of PropertyValue' do
              expect { subject.run }.to change { PropertyValue.count }.by(-1)
            end
          end
        end

        context 'when property_values for item is empty' do
          let!(:item) { create(:new_item) }
          let(:param_property_value) { { property_id: property.find_by(name: 'video').property_id, value: '' } }

          its(:run) { is_expected.to be_truthy }

          include_examples 'add new property_value'
          include_examples 'property_value invalid'
          include_examples 'add a location in item'
        end
      end
    end
  end
end
