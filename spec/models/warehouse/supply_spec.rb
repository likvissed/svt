require 'feature_helper'

module Warehouse
  RSpec.describe Supply, type: :model do
    it { is_expected.to have_many(:operations).dependent(:destroy) }
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
  end
end
