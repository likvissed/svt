require 'feature_helper'

module Warehouse
  module Items
    RSpec.describe Edit, type: :model do
      describe '#run' do
        context 'when absent property_values for item' do
          let(:item) { create(:expanded_item) }
          subject { Edit.new(item.id) }

          its(:run) { is_expected.to be_truthy }

          include_examples 'field is not blank'
          include_examples 'check key prop_data'
          include_examples 'calls service Invent::LkInvents::InitProperties'
          include_examples 'value for key file_depending'

          it 'property_values for item is blank' do
            expect(subject).to receive(:new_property_values)

            subject.run
          end

          context 'when new property_value assign value' do
            let(:property) { Invent::Property.all }

            it 'sets property_id attribute for each property_value' do
              subject.run

              subject.data[:prop_data][:file_depending].each_with_index do |val, index|
                expect(subject.data[:item]['property_values_attributes'][index]['property_id']).to eq(property.find_by(name: val).property_id)
              end
            end

            it 'sets warehouse_item_id attribute for each property_value' do
              subject.run

              subject.data[:item]['property_values_attributes'].each do |value|
                expect(value['warehouse_item_id']).to eq(item.id)
              end
            end

            it 'sets value attribute for each property_value' do
              subject.run
              subject.data[:item]['property_values_attributes'].each do |value|
                expect(value['value']).to eq('')
              end
            end
          end
        end

        context 'when present property_values for item' do
          let(:item) { create(:item_with_property_values) }
          subject { Edit.new(item.id) }

          its(:run) { is_expected.to be_truthy }

          include_examples 'field is not blank'
          include_examples 'check key prop_data'
          include_examples 'calls service Invent::LkInvents::InitProperties'
          include_examples 'value for key file_depending'

          it 'property_values not receive :new_property_values' do
            expect(subject).not_to receive(:new_property_values)

            subject.run
          end
        end
      end
    end
  end
end
