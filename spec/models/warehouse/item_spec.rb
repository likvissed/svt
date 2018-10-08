require 'feature_helper'

module Warehouse
  RSpec.describe Item, type: :model do
    it { is_expected.to have_many(:operations).dependent(:nullify) }
    it { is_expected.to have_many(:supplies).through(:operations).class_name('Warehouse::Supply').source(:operationable) }
    it { is_expected.to have_many(:orders).through(:operations).class_name('Warehouse::Order').source(:operationable) }
    it { is_expected.to belong_to(:inv_item).class_name('Invent::Item').with_foreign_key('invent_item_id') }
    it { is_expected.to belong_to(:inv_type).class_name('Invent::Type').with_foreign_key('invent_type_id') }
    it { is_expected.to belong_to(:inv_model).class_name('Invent::Model').with_foreign_key('invent_model_id') }
    it { is_expected.to validate_presence_of(:warehouse_type) }
    it { is_expected.to validate_presence_of(:item_type) }
    it { is_expected.to validate_presence_of(:item_model) }
    it { is_expected.to validate_presence_of(:count) }
    it { is_expected.to validate_presence_of(:count_reserved) }

    it { is_expected.to validate_numericality_of(:count).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:count_reserved).is_greater_than_or_equal_to(0) }


    context 'when warehouse_type is :with_invent_num' do
      subject { build(:new_item, count: 4, inv_type: Invent::Type.find_by(name: :pc), item_model: 'UNIT') }

      it { is_expected.to validate_presence_of(:invent_num_start) }
      it { is_expected.to validate_numericality_of(:invent_num_start).is_greater_than_or_equal_to(0) }
    end

    context 'when warehouse_type is :without_invent_num' do
      subject { build(:new_item, warehouse_type: :without_invent_num, invent_num_start: nil) }

      it { is_expected.to be_valid }
    end

    context 'when inv_item already exists' do
      let(:inv_item) { create(:item, :with_property_values, type_name: :monitor) }
      let!(:item) { create(:used_item, inv_item: inv_item) }
      subject { build(:used_item, inv_item: inv_item) }

      it 'uniqueness inv_item' do
        subject.valid?
        expect(subject.errors.details[:inv_item]).to include(error: :taken, value: inv_item)
      end
    end

    context 'when item and type are nil' do
      let!(:item) { create(:used_item, inv_type: nil, inv_model: nil, item_model: 'Model 1', item_type: 'Type 1') }
      let(:item_sec) { build(:used_item, inv_type: nil, inv_model: nil, item_model: 'Model 2', item_type: 'Type 2') }

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

    describe '#generate_invent_num' do
      subject { create(:new_item, count: 4, inv_type: Invent::Type.find_by(name: :pc), item_model: 'UNIT', invent_num_end: 114) }

      before { allow(subject).to receive_message_chain(:inv_items, :pluck).and_return(['111', '113']) }

      it 'generates an invent_num excluding existing' do
        expect(subject.generate_invent_num).to eq 112
      end
    end

    describe '#set_string_values' do
      context 'when inv_item exists' do
        let(:inv_item) { create(:item, :with_property_values, type_name: :monitor) }
        subject { build(:used_item, inv_item: inv_item) }

        it 'adds item_model value' do
          subject.valid?

          expect(subject.item_model).to eq inv_item.get_item_model
        end
      end

      context 'when type exists' do
        let(:type) { Invent::Type.find_by(name: :monitor) }
        subject { build(:used_item, inv_type: type) }

        it 'adds item_type value' do
          expect(subject.item_type).to eq type.short_description
        end
      end

      context 'when inv_item does not exist but model exists' do
        let(:model) { Invent::Type.find_by(name: :monitor).models.first }
        subject { build(:new_item, inv_model: model) }

        it 'adds item_model value' do
          subject.valid?
          expect(subject.item_model).to eq model.item_model
        end
      end
    end

    describe 'max_count' do
      let(:inv_item) { create(:item, :with_property_values, type_name: 'monitor') }

      context 'when count > 1' do
        subject { build(:used_item, inv_item: inv_item, count: 2) }

        it 'adds error' do
          subject.valid?

          expect(subject.errors.details[:count]).to include(error: :max_count_exceeded)
        end
      end

      context 'when count = 1' do
        subject { build(:used_item, inv_item: inv_item, count: 1) }

        it { is_expected.to be_valid }
      end

      context 'when count < 1' do
        subject { build(:used_item, inv_item: inv_item, count: 0) }

        it { is_expected.to be_valid }
      end
    end

    describe '#compare_counts' do
      context 'when count > count_reserved' do
        subject { build(:used_item, count: 1, count_reserved: 0) }

        it { is_expected.to be_valid }
      end

      context 'when count = count_reserved' do
        subject { build(:used_item, count: 1, count_reserved: 1) }

        it { is_expected.to be_valid }
      end

      context 'when count < count_reserved' do
        subject { build(:used_item, count: 0, count_reserved: 1) }

        it 'adds :out_of_stock error' do
          subject.valid?
          expect(subject.errors.details[:base]).to include(error: :out_of_stock, type: subject.item_type)
        end
      end
    end

    describe '#prevent_destroy' do
      its(:destroy) { is_expected.to be_truthy }

      context 'when item has operation with :processing status' do
        let!(:order) { create(:order, :default_workplace) }
        subject { order.items.first }

        it 'does not destroy Item' do
          expect { subject.destroy }.not_to change(Item, :count)
        end

        it 'adds :cannot_destroy_with_processing_operation error' do
          subject.destroy
          expect(subject.errors.details[:base]).to include(error: :cannot_destroy_with_processing_operation, order_id: order.id)
        end
      end

      context 'when :count_reserved attribute is not zero' do
        let!(:item) { create(:used_item, count: 1, count_reserved: 1) }

        it 'does not destroy Item' do
          expect { item.destroy }.not_to change(Item, :count)
        end

        it 'adds :cannot_destroy_with_count_reserved error' do
          item.destroy
          expect(item.errors.details[:base]).to include(error: :cannot_destroy_with_count_reserved)
        end
      end
    end

    describe '#compare_invent_nums_with_reserved' do
      let(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
      let!(:new_item) { create(:new_item, count: 4, count_reserved: 2, inv_type: Invent::Type.find_by(name: :pc), item_model: 'UNIT', invent_num_end: 114) }
      let(:operation) { attributes_for(:order_operation, item_id: new_item.id, shift: -2) }
      subject { new_item }
      context 'when one of invent_num not includes into pool' do
        before do
          order_params = attributes_for(:order, operation: :out, invent_workplace_id: workplace.workplace_id)
          order_params[:operations_attributes] = [operation]
          Warehouse::Orders::CreateOut.new(create(:***REMOVED***_user), order_params).run
          Invent::Item.last.update_attribute(:invent_num, '114')
        end

        it 'adds :invent_num_pool_is_too_small error' do
          subject.count = 2
          subject.invent_num_end = 112
          subject.valid?
          expect(subject.errors.details[:base]).to include(error: :invent_num_pool_is_too_small, model: subject.item_model)
        end
      end

      context 'when all invent_nums includes into pool' do
        before do
          order_params = attributes_for(:order, operation: :out, invent_workplace_id: workplace.workplace_id)
          order_params[:operations_attributes] = [operation]
          Warehouse::Orders::CreateOut.new(create(:***REMOVED***_user), order_params).run
          subject.count = 3
        end

        it { is_expected.to be_valid }
      end
    end
  end
end
