require 'rails_helper'

module Invent
  module Items
    RSpec.describe Show, type: :model do
      let(:item) { create(:item, :with_property_values, type_name: 'monitor') }
      subject { Show.new(item.item_id) }

      it 'fills the item at least with %w[property_values get_item_model invent_num] keys' do
        subject.run
        expect(subject.data).to include('property_values', 'get_item_model', 'invent_num')
      end

      it 'fills each property_values_attribute at least with %w[value property property_list] key' do
        subject.run
        subject.data['property_values'].each do |prop_val|
          expect(prop_val).to include('value', 'property', 'property_list')
        end
      end

      context 'when item is not found' do
        subject { Show.new(111) }

        it 'raises RecordNotFound error' do
          expect { subject.run }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end
