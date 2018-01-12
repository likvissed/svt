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
            build(:item_to_order, inv_item: workplace_1.items.first),
            build(:item_to_order, inv_item: workplace_2.items.first)
          ]
        end
        subject { build(:order, item_to_orders: item_to_orders) }

        it 'adds :uniq_workplace error' do
          expect(subject.errors.details[:base]).to include(error: :uniq_workplace)
        end

        it { is_expected.not_to be_valid }
      end

      context 'when items belongs to the one workplace' do
        let(:operations) { [build(:order_operation)] }
        subject { build(:order, operations: operations) }

        it { is_expected.to be_valid }
      end
    end

    describe '#set_initial_status' do
      it 'sets :processing status after initialize object' do
        expect(subject.status).to eq 'processing'
      end
    end

    describe '#set_consumer' do
      context 'when exists consumer_tn' do
        let(:tn) { ***REMOVED*** }
        let(:user_iss) { UserIss.find_by(tn: tn) }
        let(:new_user) { UserIss.find_by(fio: '***REMOVED***') }

        context 'and when consumer_fio already exists' do
          subject { build(:order, consumer_tn: tn, consumer_fio: new_user.fio) }

          %w[fio id_tn].each do |attr|
            it "sets a new #{attr}" do
              subject.save
              expect(subject.send("consumer_#{attr}")).to eq new_user.send(attr)
            end
          end
        end

        context 'and when consumer_fio is blank' do
          subject { build(:order, consumer_tn: tn) }

          %w[fio id_tn].each do |attr|
            it "sets a new #{attr}" do
              subject.save
              expect(subject.send("consumer_#{attr}")).to eq user_iss.send(attr)
            end
          end
        end

        context 'and when consumer not found' do
          subject { build(:order, consumer_tn: 0) }

          it 'adds :not_found error to the consumer_fio attribute' do
            subject.save
            expect(subject.errors.details[:consumer]).to include(error: :user_by_tn_not_found)
          end
        end
      end


      context 'when exists consumer_fio' do
        let(:fio) { '***REMOVED***' }
        let(:user) { UserIss.find_by(fio: fio) }

        context 'and when consumer_id_tn already exists' do
          subject { build(:order, consumer_tn: 24_079, consumer_fio: fio) }

          it 'loads a new id_tn from the UserIss table' do
            subject.save
            expect(subject.consumer_id_tn).to eq user.id_tn
          end
        end

        context 'and when consumer_id_tn is blank' do
          subject { build(:order, consumer_fio: fio) }

          it 'loads id_tn from the UserIss table' do
            subject.save
            expect(subject.consumer_id_tn).to eq user.id_tn
          end
        end

        context 'and when consumer not found' do
          subject { build(:order, consumer_fio: 'Тест') }

          it 'adds :not_found error to the consumer_fio attribute' do
            subject.save
            expect(subject.errors.details[:consumer]).to include(error: :user_by_fio_not_found)
          end
        end
      end
    end

    describe '#set_workplace' do
      let!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor], dept: ***REMOVED***) }
      let(:item_to_orders) do
        [
          build(:item_to_order, inv_item: workplace.items.first),
          build(:item_to_order, inv_item: workplace.items.last)
        ]
      end
      let(:operations) { [build(:order_operation), build(:order_operation)] }
      subject { build(:order, item_to_orders: item_to_orders, operations: operations) }

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
            build(:item_to_order, inv_item: workplace.items.first),
            build(:item_to_order, inv_item: workplace.items.last)
          ]
        end
        let(:operations) { [build(:order_operation)] }
        subject { build(:order, item_to_orders: item_to_orders, operations: operations) }

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
        let(:item_to_orders) { [build(:item_to_order, inv_item: workplace_***REMOVED***.items.last)] }
        let(:operations) { [build(:order_operation, invent_item_id: ***REMOVED***)] }
        subject { build(:order, item_to_orders: item_to_orders, operations: operations, consumer_dept: ***REMOVED***) }

        it { is_expected.not_to be_valid }

        it 'adds :dept_does_not_match error' do
          subject.valid?
          expect(subject.errors.details[:base]).to include(error: :dept_does_not_match)
        end
      end
    end
  end
end
