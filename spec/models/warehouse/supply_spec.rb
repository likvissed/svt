require 'feature_helper'

module Warehouse
  RSpec.describe Supply, type: :model do
    it { is_expected.to have_many(:operations).dependent(:destroy).inverse_of(:operationable) }
    it { is_expected.to have_many(:items).through(:operations) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to accept_nested_attributes_for(:operations).allow_destroy(true) }

    describe '#positive_operations_shift' do
      let(:operation) { build(:supply_operation, shift: 1) }
      subject { build(:supply, operations: [operation]) }

      it { is_expected.to be_valid }

      context 'when one of operation has negative value' do
        let(:operation) { build(:supply_operation, shift: -1) }
        subject { build(:supply, operations: [operation]) }

        it 'adds :operations_can_not_have_negative_value error' do
          subject.valid?
          expect(subject.errors.details[:base]).to include(error: :operations_can_not_have_negative_value)
        end
      end
    end

    describe '#checked_location_for_items' do
      let(:item_without_location) { create(:expanded_item) }
      let(:operation) { build(:supply_operation, shift: 1, item: item_without_location) }
      subject { build(:supply, operations: [operation], location_attr: true, value_location_item_type: item_without_location.item_type) }

      it 'adds :must_add_a_location_for_the_item error' do
        subject.valid?

        expect(subject.errors.details[:base]).to include(error: :must_add_a_location_for_the_item, item_type: item_without_location.item_type)
      end
    end
  end
end
