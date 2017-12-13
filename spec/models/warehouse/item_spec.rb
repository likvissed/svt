require 'rails_helper'

module Warehouse
  RSpec.describe Item, type: :model do
    it { is_expected.to belong_to(:inv_item).class_name('Invent::Item').with_foreign_key('invent_item_id') }
    it { is_expected.to belong_to(:type).class_name('Invent::Type') }
    it { is_expected.to belong_to(:model).class_name('Invent::Model') }
    it { is_expected.to validate_presence_of(:warehouse_type) }
    it { is_expected.to validate_presence_of(:inv_item) }
    it { is_expected.to validate_presence_of(:item_type) }
    it { is_expected.to validate_presence_of(:item_model) }
    it { is_expected.to validate_presence_of(:used) }
    it { is_expected.to validate_presence_of(:count) }
    it { is_expected.to validate_presence_of(:count_reserved) }
    it { is_expected.to validate_numericality_of(:count).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:count_reserved).is_greater_than_or_equal_to(0) }

    it 'uniqueness of model' do
      expect(create(:used_item)).to validate_uniqueness_of(:model).scoped_to(:type_id)
    end

    # FIXME: спека не проходит
    # it 'uniqueness of item_model' do
    #   expect(create(:used_item)).to validate_uniqueness_of(:item_model).scoped_to(:item_type)
    # end

    context 'when item and type are nil' do
      let!(:item) { create(:used_item, type: nil, model: nil, item_model: 'Model 1', item_type: 'Type 1') }
      let(:item_sec) { build(:used_item, type: nil, model: nil, item_model: 'Model 2', item_type: 'Type 2') }

      it 'should be valid' do
        expect(item_sec).to be_valid
      end
    end

    describe '#set_initial_count' do
      it 'sets :processing status after initialize object' do
        expect(subject.count).to be_zero
        expect(subject.count_reserved).to be_zero
      end
    end
  end
end
