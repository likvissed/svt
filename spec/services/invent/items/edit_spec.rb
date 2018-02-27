require 'feature_helper'

module Invent
  module Items
    RSpec.describe Edit, type: :model do
      let(:item) { create(:item, :with_property_values, type_name: 'monitor') }
      let(:show) { Show.new(item.item_id) }
      subject { Edit.new(item.item_id) }

      it 'loads item with specified item_id' do
        subject.run
        expect(subject.data['id']). to eq item.item_id
      end

      it 'change status of item' do
        subject.run
        expect(subject.data['status']).to eq :waiting_take
      end

      it 'fills the item at least with %w[id property_values_attributes get_item_model invent_num] keys' do
        subject.run
        expect(subject.data).to include('id', 'property_values_attributes', 'get_item_model', 'invent_num')
      end

      it 'fills each property_values_attribute at least with %w[id value property_list] key' do
        subject.run
        subject.data['property_values_attributes'].each do |prop_val|
          expect(prop_val).to include('id', 'value', 'property_list')
        end
      end

      context 'when item is not found' do
        subject { Edit.new(111) }

        it 'raises RecordNotFound error' do
          expect { subject.run }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end
