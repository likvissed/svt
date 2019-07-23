require 'feature_helper'

module Warehouse
  module Items
    RSpec.describe Edit, type: :model do
      describe '#run' do
        context 'when absent item_property_values for item' do
          let(:item) { create(:expanded_item) }
          subject { Edit.new(item.id) }

          its(:run) { is_expected.to be_truthy }

          %w[mb ram video cpu hdd].each do |value|
            it "field :file_depending includes '#{value}'" do
              subject.run

              expect(subject.data[:file_depending]).to include(value)
            end
          end

          include_examples 'fields is not blank'

          it 'item_property_values not exist' do
            expect(subject).to receive(:load_property)

            subject.run
          end
        end

        context 'when present item_property_values for item' do
          let(:item) { create(:item_property_values) }
          subject { Edit.new(item.id) }

          its(:run) { is_expected.to be_truthy }

          include_examples 'fields is not blank'

          it 'array :property_values_attributes sorted' do
            item.item_property_values.joins(:property).merge(Invent::Property.order(:property_order)).each_with_index do |value, index|
              subject.run

              expect(value.property_id).to eq subject.data[:property_values_attributes][index].property_id
            end
          end

          it 'item_property_values present' do
            expect(subject).to receive(:load_property_value)

            subject.run
          end
        end
      end
    end
  end
end
