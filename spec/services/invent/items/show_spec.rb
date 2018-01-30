require 'rails_helper'

module Invent
  module Items
    RSpec.describe Show, type: :model do
      let(:item) { create(:item, :with_property_values, type_name: 'monitor') }
      subject { Show.new(item.item_id) }

      it 'fills the item at least with %w[id property_values_attributes] keys' do
        subject.run
        expect(subject.data).to include('id', 'property_values_attributes')
      end

      it 'fills each property_values_attribute at least with "id" key' do
        subject.run
        subject.data['property_values_attributes'].each do |prop_val|
          expect(prop_val).to include('id')
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
