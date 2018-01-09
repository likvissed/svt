require 'rails_helper'

module Warehouse
  RSpec.describe Order, type: :model do
    it { is_expected.to have_many(:operations).dependent(:destroy) }
    it { is_expected.to have_many(:item_to_orders).dependent(:destroy) }
    it { is_expected.to have_many(:inv_items).through(:item_to_orders).class_name('Invent::Item') }
    it { is_expected.to have_many(:items).through(:operations) }
    it { is_expected.to belong_to(:workplace).class_name('Invent::Workplace') }
    it { is_expected.to belong_to(:creator).class_name('UserIss').with_foreign_key('creator_id_tn') }
    it { is_expected.to belong_to(:consumer).class_name('UserIss').with_foreign_key('consumer_id_tn') }
    it { is_expected.to belong_to(:validator).class_name('UserIss').with_foreign_key('validator_id_tn') }
    it { is_expected.to validate_presence_of(:operation) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:creator_fio) }
    it { is_expected.not_to validate_presence_of(:consumer_fio) }
    it { is_expected.to validate_presence_of(:consumer_dept) }
    it { is_expected.not_to validate_presence_of(:validator_fio) }
    it { is_expected.to accept_nested_attributes_for(:operations).allow_destroy(true) }
    it { is_expected.to accept_nested_attributes_for(:item_to_orders).allow_destroy(true) }

    context 'when status is :done' do
      subject { build(:order, status: :done) }

      it { is_expected.to validate_presence_of(:consumer_fio) }
    end

    context 'when status is :done and operation is :out' do
      subject { build(:order, status: :done, operation: :out) }

      it { is_expected.to validate_presence_of(:validator_fio) }
    end

    describe '#uniqueness_of_workplace' do
      let!(:workplace_1) { create(:workplace_pk, :add_items, items: %i[pc monitor], dept: ***REMOVED***) }
      let!(:workplace_2) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
      before { subject.valid? }

      context 'when items belongs to the different workplaces' do
        let(:item_to_orders) do
          [
            { invent_item_id: workplace_1.items.first.item_id },
            { invent_item_id: workplace_2.items.first.item_id }
          ]
        end
        subject { build(:order, item_to_orders_attributes: item_to_orders) }

        it 'adds :uniq_workplace error' do
          expect(subject.errors.details[:base]).to include(error: :uniq_workplace)
        end

        it { is_expected.not_to be_valid }
      end

      context 'when items belongs to the one workplace' do
        let(:operations) { [attributes_for(:order_operation)] }
        subject { build(:order, operations_attributes: operations) }

        it { is_expected.to be_valid }
      end
    end

    describe '#set_initial_status' do
      it 'sets :processing status after initialize object' do
        expect(subject.status).to eq 'processing'
      end
    end

    describe '#set_workplace' do
      let!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor], dept: ***REMOVED***) }
      let(:item_to_orders) do
        [
          { invent_item_id: workplace.items.first.item_id },
          { invent_item_id: workplace.items.last.item_id }
        ]
      end
      let(:operations) do
        [
          attributes_for(:order_operation),
          attributes_for(:order_operation)
        ]
      end
      subject { build(:order, item_to_orders_attributes: item_to_orders, operations_attributes: operations) }

      it 'sets :workplace references after validate object' do
        expect { subject.valid? }.to change(subject, :workplace_id).to(workplace.workplace_id)
      end
    end

    describe '#set_creator' do
      let(:user) { create(:user) }
      before { subject.set_creator(user) }

      it 'sets creator_id_tn' do
        expect(subject.creator_id_tn).to eq user.id_tn
      end

      it 'sets creator_fio' do
        expect(subject.creator_fio).to eq user.fullname
      end
    end

    describe '#at_least_one_operation' do
      subject { build(:order, :without_operations) }

      it 'adds :at_least_one_inv_item error if operations is empty' do
        subject.valid?
        expect(subject.errors.details[:base]).to include(error: :at_least_one_operation)
      end
    end

    describe '#compare_nested_attrs' do
      context 'when nested arrays not equals' do
        let!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor], dept: ***REMOVED***) }
        let(:item_to_orders) do
          [
            { invent_item_id: workplace.items.first.item_id },
            { invent_item_id: workplace.items.last.item_id }
          ]
        end
        let(:operations) { [attributes_for(:order_operation)] }
        subject { build(:order, item_to_orders_attributes: item_to_orders, operations_attributes: operations) }

        it 'adds :nested_arrs_not_equals error' do
          subject.valid?
          expect(subject.errors.details[:base]).to include(error: :nested_arrs_not_equals)
        end
      end
    end

    describe '#compare_consumer_dept' do
      context 'when consumer_dept does not match with division of the selected item' do
        let!(:workplace_***REMOVED***) { create(:workplace_pk, :add_items, items: %i[pc monitor], dept: ***REMOVED***) }
        let!(:workplace_***REMOVED***) { create(:workplace_pk, :add_items, items: %i[pc monitor], dept: ***REMOVED***) }
        let(:item_to_orders) { [{ invent_item_id: workplace_***REMOVED***.items.last.item_id }] }
        let(:operations) { [attributes_for(:order_operation, invent_item_id: ***REMOVED***)] }
        subject { build(:order, item_to_orders_attributes: item_to_orders, operations_attributes: operations, consumer_dept: ***REMOVED***) }

        it { is_expected.not_to be_valid }

        it 'adds :dept_does_not_match error' do
          subject.valid?
          expect(subject.errors.details[:base]).to include(error: :dept_does_not_match)
        end
      end
    end
  end
end
