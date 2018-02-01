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

    context 'when status is :done and operation is :out' do
      subject { build(:order, status: :done, operation: :out) }

      it { is_expected.to validate_presence_of(:validator_fio) }
    end

    describe '#presence_consumer' do
      subject { build(:order, operations: operations) }
      before { subject.valid? }

      context 'when one of operations status is done' do
        let(:operations) { [build(:order_operation, status: :done), build(:order_operation)] }

        it 'adds error :blank to the consumer' do
          expect(subject.errors.details[:consumer]).to include(error: :blank)
        end
      end

      context 'when all of operations status is processing' do
        let(:operations) { [build(:order_operation), build(:order_operation)] }

        it 'adds error :blank to the consumer' do
          expect(subject.errors.details[:consumer]).to be_empty
        end
      end
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
        let(:operation_1) { build(:order_operation, invent_item_id: workplace_1.items.first.item_id) }
        let(:operation_2) { build(:order_operation, invent_item_id: workplace_1.items.last.item_id) }
        subject { build(:order, workplace: workplace_1, operations: [operation_1, operation_2]) }

        it { is_expected.to be_valid }
      end

      context 'when one of item does not have workplace' do
        let(:item_to_orders) do
          [
            build(:item_to_order, inv_item: workplace_1.items.first),
            build(:item_to_order, inv_item: workplace_1.items.last)
          ]
        end
        subject { build(:order, workplace: workplace_1, item_to_orders: item_to_orders) }
        before { Invent::Item.first.update(workplace: nil) }

        it 'not adds :uniq_workplace error' do
          expect(subject.errors.details[:base]).not_to include(error: :uniq_workplace)
        end
      end
    end

    describe '#set_initial_status' do
      it 'sets :processing status after initialize object' do
        expect(subject.status).to eq 'processing'
      end

      context 'when status already exists' do
        subject { build(:order, status: :done) }

        it 'does not change status' do
          subject.valid?
          expect(subject.done?).to be_truthy
        end
      end
    end

    describe '#calculate_status' do
      let(:user) { create(:user) }
      subject { build(:order, operations: operations, consumer_tn: user.tn) }

      context 'when all operations is done' do
        let(:operations) do
          [
             build(:order_operation, status: :done, stockman_id_tn: user.id_tn),
             build(:order_operation, status: :done, stockman_id_tn: user.id_tn)
          ]
        end

        it 'sets status :done' do
          subject.save
          expect(subject.reload.done?).to be_truthy
        end
      end

      context 'when not all operations is done' do
        let(:operations) do
          [
             build(:order_operation, status: :done, stockman_id_tn: user.id_tn),
             build(:order_operation, status: :processing)
          ]
        end

        it 'sets status :processing' do
          subject.save
          expect(subject.reload.processing?).to be_truthy
        end
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

      describe '#set_closed_time' do
        context 'when status is :done' do
          let(:date) { DateTime.now }
          before { allow(DateTime).to receive(:new).and_return(date) }
          subject { build(:order, status: :done) }

          it 'sets current time to the :closed_time attribute' do
            subject.save
            expect(subject.closed_time.utc.to_s).to eq date.utc.to_s
          end
        end

        context 'when status is :processing' do
          subject { build(:order, status: :processing) }

          it 'does not change :closed_time attribute' do
            subject.save
            expect(subject.closed_time).to be_nil
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

    describe '#prevent_destroy' do
      let(:user) { create(:user) }

      context 'when order is done' do
        let(:operation) { build(:order_operation, status: :done, stockman_id_tn: user.id_tn) }
        let!(:order) { create(:order, operations: [operation], consumer_tn: user.tn) }

        include_examples 'does not destroy'

        it 'adds :cannot_destroy_done error' do
          order.destroy
          expect(order.errors.details[:base]).to include(error: :cannot_destroy_done)
        end
      end

      context 'when one of operation is done' do
        let(:operation_1) { build(:order_operation, status: :done, stockman_id_tn: user.id_tn) }
        let(:operation_2) { build(:order_operation) }
        let!(:order) { create(:order, operations: [operation_1, operation_2], consumer_tn: user.tn) }

        include_examples 'does not destroy'

        it 'adds :cannot_destroy_with_done_operations error' do
          order.destroy
          expect(order.errors.details[:base]).to include(error: :cannot_destroy_with_done_operations)
        end
      end

      context 'when order still processing' do
        subject { create(:order) }

        its(:destroy) { is_expected.to be_truthy }
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
      context 'when operations is empty' do
        subject { build(:order, :without_operations) }

        it 'adds :at_least_one_inv_item error' do
          subject.valid?
          expect(subject.errors.details[:base]).to include(error: :at_least_one_operation)
        end
      end

      context 'when operations is exists but _destroy is eq 1' do
        let(:order) { create(:order) }
        let(:order_json) { order.as_json(include: :operations) }
        subject do
          order_json['operations_attributes'] = order_json['operations']
          order_json['operations_attributes'].each do |op|
            op['id'] = op['warehouse_operation_id']
            op['_destroy'] = 1

            op.delete('warehouse_operation_id')
          end

          order_json.delete('operations')
          order.assign_attributes(order_json)
          order
        end

        it 'adds :at_least_one_inv_item error' do
          subject.valid?
          expect(subject.errors.details[:base]).to include(error: :at_least_one_operation)
        end
      end

      context 'when operations exist' do
        subject { build(:order) }

        it { is_expected.to be_valid }
      end
    end

    describe '#compare_nested_arrs' do
      context 'when nested arrays not equals' do
        let!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor], dept: ***REMOVED***) }
        let(:item_to_orders) do
          [
            build(:item_to_order, inv_item: workplace.items.first),
            build(:item_to_order, inv_item: workplace.items.last)
          ]
        end
        let(:operations) { [build(:order_operation, invent_item_id: workplace.items.first.item_id)] }
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
        let(:operations) { [build(:order_operation, invent_item_id: workplace_***REMOVED***.items.last.item_id)] }
        subject { build(:order, item_to_orders: item_to_orders, operations: operations, consumer_dept: ***REMOVED***) }

        it { is_expected.not_to be_valid }

        it 'adds :dept_does_not_match error' do
          subject.valid?
          expect(subject.errors.details[:base]).to include(error: :dept_does_not_match)
        end
      end

      context 'when invent_item already does not have workplace_id (workplace was removed?)' do
        let(:item) { create(:item, :with_property_values, type_name: :monitor) }
        let(:item_to_orders) { [build(:item_to_order, inv_item: item)] }
        let(:operation) { build(:order_operation, invent_item_id: item.item_id) }
        subject { build(:order, item_to_orders: item_to_orders, operations: [operation], consumer_dept: ***REMOVED***) }

        it 'does not add :dept_does_not_match error' do
          subject.valid?
          expect(subject.errors.details[:base]).not_to include(error: :dept_does_not_match)
        end
      end
    end

    describe '#check_operation_list' do
      let(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
      before do
        subject.operations << new_operation
        subject.valid?
      end

      context 'when warehouse_type of items is :expendable (workplace is not exist)' do
        let(:old_operation) { build(:order_operation, item_type: 'Клавиатура', item_model: 'OKLICK') }
        let(:new_operation) { build(:order_operation, invent_item_id: workplace.items.first.item_id) }
        subject { create(:order, operations: [old_operation]) }

        it 'not allow to add to the operations any items with invent_item_id' do
          expect(subject.errors.details[:base]).to include(error: :cannot_have_operations_with_invent_num)
        end
      end

      context 'when warehouse_type of items is :returnable (workplace is exists)' do
        let(:old_operation) { build(:order_operation, invent_item_id: workplace.items.first.item_id) }
        subject { create(:order, workplace: workplace, operations: [old_operation]) }

        context 'and when add operations without invent_item_id' do
          let(:new_operation) { build(:order_operation, item_type: 'Клавиатура', item_model: 'OKLICK') }

          it 'adds :cannot_have_operations_without_invent_num error' do
            expect(subject.errors.details[:base]).to include(error: :cannot_have_operations_without_invent_num)
          end
        end
      end
    end

    describe '#prevent_update_done_order' do
      let(:user) { create(:user) }
      let(:operation) { build(:order_operation, status: :done, stockman_id_tn: user.id_tn) }
      subject { create(:order, operations: [operation], consumer_tn: user.tn) }

      context 'when status was done' do
        context 'and status changed' do
          before { subject.status = 'processing' }

          include_examples ':cannot_update_done_order error'
        end

        context 'and another attribute was changed' do
          let(:new_user) { create(:***REMOVED***_user) }
          before { subject.validator_fio = new_user.fullname }

          include_examples ':cannot_update_done_order error'
        end
      end
    end

    describe '#prevent_update_attributes' do
      let(:user) { create(:user) }
      subject { create(:order) }
      let!(:old_params) do
        {
          workplace_id: subject.workplace_id,
          operation: subject.operation,
          consumer_dept: subject.consumer_dept
        }
      end

      it 'prevents changes of :workplace attribute' do
        subject.workplace_id = 123
        subject.save
        expect(subject.reload.workplace_id).to eq old_params[:workplace_id]
        expect(subject.errors.details[:workplace]).to include(error: :cannot_update)
      end

      it 'prevents changes of :operation attribute' do
        subject.operation = :out
        subject.save
        expect(subject.reload.operation).to eq old_params[:operation]
        expect(subject.errors.details[:operation]).to include(error: :cannot_update)
      end

      it 'prevents changes of :consumer_dept attribute' do
        subject.consumer_dept = 123
        subject.save
        expect(subject.reload.consumer_dept).to eq old_params[:consumer_dept]
        expect(subject.errors.details[:consumer_dept]).to include(error: :cannot_update)
      end
    end
  end
end
