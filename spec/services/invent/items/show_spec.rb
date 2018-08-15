require 'feature_helper'

module Invent
  module Items
    RSpec.describe Show, type: :model do
      let(:item) { create(:item, :with_property_values, type_name: 'monitor') }

      context 'when receive item_id' do
        subject { Show.new({ item_id: item.item_id}) }

        it 'fills the item at least with %w[property_values get_item_model invent_num] keys' do
          subject.run
          subject.data.each do |i|
            expect(i).to include('property_values', 'get_item_model', 'invent_num')
          end
        end

        it 'fills each property_values_attribute at least with %w[value property property_list] key' do
          subject.run
          subject.data.each do |i|
            i['property_values'].each do |prop_val|
              expect(prop_val).to include('value', 'property', 'property_list')
            end
          end
        end

        # context 'when item is not found' do
        #   subject { Show.new({ item_id: 111 }) }

        #   it 'raises RecordNotFound error' do
        #     expect { subject.run }.to raise_error(ActiveRecord::RecordNotFound)
        #   end
        # end
      end

      context 'test' do
        subject { Show.new("1=1; SELECT * FROM users --") }

        it 'test' do

        end
      end

      context 'when receive invent_num' do
        subject { Show.new({ invent_num: item.invent_num}) }

        it 'fills the item at least with %w[property_values get_item_model invent_num] keys' do
          subject.run
          subject.data.each do |i|
            expect(i).to include('property_values', 'get_item_model', 'invent_num')
          end
        end

        it 'fills each property_values_attribute at least with %w[value property property_list] key' do
          subject.run
          subject.data.each do |i|
            i['property_values'].each do |prop_val|
              expect(prop_val).to include('value', 'property', 'property_list')
            end
          end
        end
      end
    end
  end
end
