require 'feature_helper'

module Invent
  module Items
    RSpec.describe Edit, type: :model do
      let(:item) { create(:item, :with_property_values, type_name: 'monitor') }
      # let(:show) { Show.new({ item_id: ite`m.item_id }) }
      subject { Edit.new(item.item_id) }

      it 'loads item with specified item_id' do
        subject.run
        expect(subject.data[:item]['id']). to eq item.item_id
      end

      it 'fills the item at least with %w[id property_values_attributes get_item_model invent_num] keys' do
        subject.run
        expect(subject.data[:item]).to include('id', 'property_values_attributes', 'get_item_model', 'invent_num')
      end

      it 'fills each property_values_attribute at least with %w[id value property_list] key' do
        subject.run
        subject.data[:item]['property_values_attributes'].each do |prop_val|
          expect(prop_val).to include('id', 'value', 'property_list')
        end
      end

      context 'when with_init_props flag is set' do
        subject { Edit.new(item.item_id, true) }

        it 'runs LkInvents::InitProperties service' do
          expect_any_instance_of(LkInvents::InitProperties).to receive(:run)
          subject.run
        end

        it 'fills the @data with %w[item prop_data] keys' do
          subject.run
          expect(subject.data).to include(:item, :prop_data)
        end
      end

      context 'when property_value does not exist for corresponding property' do
        let(:item) do
          i = create(:item, :with_property_values, type_name: :ups)
          Invent::PropertyValue.destroy_all
          i
        end
        let(:ups_type) { Invent::Type.find_by(name: :ups) }
        let(:list_prop) { ups_type.properties.find_by(property_type: 'list') }
        let(:list_index) { ups_type.properties.index(list_prop) }
        let(:model_prop_list) do
          Invent::ModelPropertyList.find_by(
            model_id: item.model_id,
            property_id: list_prop.property_id
          )
        end
        subject { Edit.new(item.item_id, true) }

        it 'creates a missing property_values' do
          subject.run
          expect(subject.data[:item]['property_values_attributes'].size).to eq ups_type.properties.size
        end

        it 'sets property_id attribute for each missing property_value' do
          subject.run
          subject.data[:item]['property_values_attributes'].each do |prop_val|
            expect(ups_type.properties.any? { |prop| prop['property_id'] == prop_val['property_id'] }).to be_truthy
          end
        end

        it 'sets default property_value_id attribute for each missing property_value which has :list or :list_plus type' do
          subject.run

          expect(subject.data[:item]['property_values_attributes'][list_index]['property_list_id']).to eq model_prop_list.property_list_id
        end
      end
    end
  end
end
