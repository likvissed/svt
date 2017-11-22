require 'rails_helper'

module Invent
  module Items
    RSpec.describe Show, type: :model do
      let(:item) { create(:item_with_model_id, :with_property_values, workplace: nil, type_name: 'monitor') }
      subject { Show.new(item.item_id) }

      it 'fills the item at least with %w[id inv_property_values_attributes] keys' do
        subject.run
        expect(subject.data).to include('id', 'inv_property_values_attributes')
      end

      it 'fills each inv_property_values_attribute at least with "id" key' do
        subject.run
        subject.data['inv_property_values_attributes'].each do |prop_val|
          expect(prop_val).to include('id')
        end
      end

      context 'when item is not found' do
        subject { Show.new(111) }

        it 'raises RecordNotFound error' do
          expect { subject.run }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end
  end
end