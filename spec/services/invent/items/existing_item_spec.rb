require 'spec_helper'

module Invent
  module Items
    RSpec.describe ExistingItem, type: :model do
      let(:item) { create(:item, :with_property_values, item_model: 'model', type_name: 'printer') }
      subject { ExistingItem.new(Type::ALL_PRINT_TYPES, item.invent_num) }

      context 'when item exists' do
        before { subject.run }

        it 'adds %w[exists type model connection_type] keys to the data' do
          expect(subject.data).to include(:exists, :type, :model)
        end

        it 'sets true to the exists key' do
          expect(subject.data[:exists]).to be_truthy
        end

        it 'sets short_description to the :type key' do
          expect(subject.data[:type]).to eq item.type.short_description
        end

        it 'sets item_model to the :model key' do
          expect(subject.data[:model]).to eq item.full_item_model
        end
      end

      context 'when item does not exist' do
        before do
          allow(Item).to receive_message_chain(:left_outer_joins, :where, :find_by).and_return(nil)
          subject.run
        end

        it 'adds only :exists key' do
          expect(subject.data).not_to include(:type, :model)
        end

        it 'sets false to the :exists key' do
          expect(subject.data[:exists]).to be_falsey
        end
      end
    end
  end
end
