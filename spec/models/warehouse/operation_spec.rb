require 'rails_helper'

module Warehouse
  RSpec.describe Operation, type: :model do
    it { is_expected.to belong_to(:item).with_foreign_key('warehouse_item_id') }
    it { is_expected.to belong_to(:location).with_foreign_key('warehouse_location_id') }
    it { is_expected.to belong_to(:stockman).class_name('UserIss').with_foreign_key('stockman_id_tn') }
    it { is_expected.to belong_to(:operationable) }
    it { is_expected.to validate_presence_of(:item_type) }
    it { is_expected.to validate_presence_of(:item_model) }
    it { is_expected.to validate_presence_of(:shift) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.not_to validate_presence_of(:stockman_fio) }
    it { is_expected.not_to validate_presence_of(:date) }
    it { is_expected.to accept_nested_attributes_for(:item).allow_destroy(false) }

    context 'when status is done' do
      subject { build(:order_operation, status: :done) }

      it { is_expected.to validate_presence_of(:stockman_fio) }
      # it { is_expected.to validate_presence_of(:date) }
    end

    describe '#set_initial_status' do
      it 'sets :processing status after initialize object' do
        expect(subject.status).to eq 'processing'
      end

      context 'when status already exists' do
        subject { build(:order_operation, status: :done) }

        it 'does not change status' do
          subject.valid?
          expect(subject.done?).to be_truthy
        end
      end
    end

    describe '#uniq_item_by_processing_operation' do
      context 'when operation with :processing status for specified item exists' do
        let(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor monitor]) }
        let(:item) { workplace.items.first }
        let(:used_item) { create(:used_item, inv_item: item) }
        let(:operation) { build(:order_operation, invent_item_id: item.item_id, item: used_item) }
        let!(:order) { create(:order, workplace: workplace, operations: [operation]) }
        subject { build(:order_operation, item: order.items.first) }

        it 'adds :operation_already_exists error' do
          subject.valid?
          expect(subject.errors.details[:base]).to include(
            error: :operation_already_exists,
            type: used_item.item_type,
            invent_num: item.invent_num,
            order_id: order.warehouse_order_id
          )
        end
      end
    end

    describe '#set_date' do
      let(:date) { DateTime.now }
      before { allow(DateTime).to receive(:new).and_return(date) }

      context 'when status is :done' do
        subject { build(:order_operation, status: :done) }

        it 'sets current date to the :date attribute' do
          subject.save
          expect(subject.date.utc.to_s).to eq date.utc.to_s
        end
      end

      context 'when status is :processing' do
        subject { build(:order_operation) }

        it 'sets current date to the :date attribute' do
          subject.save
          expect(subject.date).to be_nil
        end
      end
    end

    describe '#prevent_update' do
      let(:user) { create(:user) }
      subject { create(:order_operation, status: :done, stockman_id_tn: user.id_tn) }

      context 'when status was done' do
        context 'and status changed' do
          before { subject.status = 'processing' }

          include_examples ':cannot_update_done_operation error'
        end

        context 'and another attribute was changed' do
          let(:new_user) { create(:***REMOVED***_user) }
          before { subject.set_stockman(new_user) }

          include_examples ':cannot_update_done_operation error'
        end
      end
    end
  end
end
