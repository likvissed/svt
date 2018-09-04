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
    end
  end
end
