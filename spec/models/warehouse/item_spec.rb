require 'rails_helper'

module Warehouse
  RSpec.describe Item, type: :model do
    it { is_expected.to belong_to(:inv_item).class_name('Invent::Item').with_foreign_key('invent_item_id') }
    it { is_expected.to belong_to(:type).class_name('Invent::Type') }
    it { is_expected.to belong_to(:model).class_name('Invent::Model') }
    it { is_expected.to validate_presence_of(:warehouse_type) }
    it { is_expected.to validate_presence_of(:item_type) }
    it { is_expected.to validate_presence_of(:item_model) }
    it { is_expected.to validate_presence_of(:count) }
    it { is_expected.to validate_presence_of(:count_reserved) }
    it { is_expected.to validate_numericality_of(:count).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:count_reserved).is_greater_than_or_equal_to(0) }

    context 'when inv_item already exists' do
      let(:inv_item) { create(:item, :with_property_values, type_name: :monitor) }
      let!(:item) { create(:used_item, inv_item: inv_item) }
      subject { build(:used_item, inv_item: inv_item) }

      it 'uniqueness inv_item' do
        subject.valid?
        puts subject.errors.full_messages
        expect(subject.errors.details[:inv_item]).to include(error: :taken, value: inv_item)
      end
    end

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

    describe '#set_string_values' do
      let(:inv_item) { create(:item, :with_property_values, type_name: :monitor) }
      subject { build(:used_item, inv_item: inv_item) }
      before { subject.valid? }

      it 'adds item_model value' do
        expect(subject.item_model).to eq inv_item.get_item_model
      end

      it 'adds item_type value' do
        expect(subject.item_type).to eq inv_item.type.short_description
      end
    end

    describe '#uniq_item_model' do
      let(:inv_item) { create(:item, :with_property_values, type_name: :monitor, item_model: 'model 1') }
      let!(:item) { create(:used_item, inv_item: inv_item) }

      context 'when :used is true' do
        let!(:item) { create(:used_item, inv_item: inv_item) }
        subject { build(:used_item, inv_item: inv_item, used: true) }

        it 'does not have :taken error' do
          subject.valid?
          expect(subject.errors.details[:item_model]).not_to include(error: :taken)
        end
      end

      context 'when item_model exists' do
        let(:inv_item_2) { create(:item, :with_property_values, type_name: :monitor, item_model: 'model 1') }
        subject { build(:used_item, inv_item: inv_item_2, used: false) }

        it { is_expected.to be_valid }

        context 'and when :used was false' do
          let!(:item) { create(:used_item, inv_item: inv_item, used: false) }

          it 'has :taken error' do
            subject.valid?
            expect(subject.errors.details[:item_model]).to include(error: :taken)
          end
        end
      end
    end
  end
end
