require 'feature_helper'

module Warehouse
  RSpec.describe Order, type: :model do
    it { is_expected.to have_many(:operations).dependent(:destroy) }
    it { is_expected.to have_many(:inv_items).through(:operations) }
    it { is_expected.to have_many(:inv_item_to_operations).through(:operations) }
    it { is_expected.to have_many(:items).through(:operations) }
    it { is_expected.to belong_to(:inv_workplace).with_foreign_key('invent_workplace_id').class_name('Invent::Workplace') }
    it { is_expected.to belong_to(:creator).class_name('UserIss').with_foreign_key('creator_id_tn') }
    it { is_expected.to belong_to(:consumer).class_name('UserIss').with_foreign_key('consumer_id_tn') }
    it { is_expected.to belong_to(:validator).class_name('UserIss').with_foreign_key('validator_id_tn') }
    it { is_expected.to validate_presence_of(:operation) }
    # it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:creator_fio) }
    it { is_expected.not_to validate_presence_of(:consumer_fio) }
    it { is_expected.not_to validate_presence_of(:consumer_dept) }
    it { is_expected.not_to validate_presence_of(:validator_fio) }
    it { is_expected.to accept_nested_attributes_for(:operations).allow_destroy(true) }

    context 'when status is :done and operation is :out' do
      subject { build(:order, status: :done, operation: :out) }
      before { subject.skip_validator = false }

      # it { is_expected.to validate_presence_of(:validator_fio) }
      it 'adds :empty error' do
        subject.valid?
        expect(subject.errors.details[:validator_fio]).to include(error: :blank)
      end
    end

    context 'when operation is :out' do
      subject { build(:order, operation: :out) }

      it { is_expected.to validate_presence_of(:invent_workplace_id) }
    end

    describe 'validates invent_num ' do
      context 'when warehouse_type has :without_invent_num value' do
        let(:used_item) { create(:used_item, warehouse_type: 'without_invent_num') }
        let(:operation) { create(:order_operation, item_id: used_item.id) }
        subject { build(:order, operations: [operation], operation: 'out') }

        it { is_expected.to validate_presence_of(:invent_num) }

        context 'and when operation is :in' do
          include_examples 'does not pass verification presence_of(:invent_num) of operation :in'
        end
      end

      context 'when warehouse_type has :with_invent_num value' do
        let(:used_item) { create(:used_item) }
        let(:operation) { create(:order_operation, item_id: used_item.id) }
        subject { build(:order, operations: [operation]) }

        it { is_expected.to_not validate_presence_of(:invent_num) }
      end

      context 'when warehouse_type has any value' do
        let(:used_item1) { create(:used_item, warehouse_type: 'without_invent_num') }
        let(:used_item2) { create(:used_item) }
        let(:operation) { [create(:order_operation, item_id: used_item1.id), create(:order_operation, item_id: used_item2.id)] }
        subject { build(:order, operations: operation, operation: 'out') }

        it { is_expected.to validate_presence_of(:invent_num) }

        context 'and when operation is :in' do
          include_examples 'does not pass verification presence_of(:invent_num) of operation :in'
        end
      end
    end

    describe '#present_invent_workplace_id' do
      let(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
      subject { build(:order, inv_workplace: workplace, operation: :out) }

      it { is_expected.to be_valid }

      context 'when workplace id does not exist' do
        before { workplace.workplace_id = 121_120 }

        it 'adds :workplace_not_present error' do
          subject.valid?

          expect(subject.errors.details[:base]).to include(error: :workplace_not_present, workplace_id: workplace.workplace_id)
        end
      end
    end

    describe '#present_user_iss' do
      let(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }

      context 'when user_iss exists' do
        subject { build(:order, inv_workplace: workplace, operation: :out, invent_num: 123) }

        it 'save order' do
          expect(subject.valid?).to be_truthy
        end
      end

      context 'when user_iss blank' do
        subject { build(:order, inv_workplace: workplace, operation: :out, invent_num: 123) }

        before { allow(workplace).to receive(:user_iss).and_return(nil) }

        it 'not save order' do
          subject.invalid?

          expect(subject.errors.details[:base]).to include(error: :absence_responsible)
        end
      end
    end

    describe '#present_item_for_barcode' do
      let(:status) { :in_workplace }
      let(:inv_item) { create(:item, :with_property_values, type_name: :printer, status: status) }

      let(:workplace) do
        w = build(:workplace_net_print, items: [inv_item])
        w.save(validate: false)
        w
      end

      subject { build(:order, inv_workplace: workplace, operation: :out, invent_num: workplace.items.first.invent_num) }

      before { subject.property_with_barcode = true }

      it { is_expected.to be_valid }

      context 'when status workplace incorrectly' do
        let(:status) { :waiting_bring }
        let(:barcode_id) { subject.inv_workplace.items.first.barcode_item.id }

        it 'adds :status_item_on_workplace_not_in_workplace error' do
          subject.invalid?

          expect(subject.errors.details[:base]).to include(error: :status_item_on_workplace_not_in_workplace, item_barcode: barcode_id)
        end
      end

      context 'when workplace entered incorrectly' do
        let(:not_present_workplace) { 901_101 }
        before { subject.invent_workplace_id = not_present_workplace }

        it 'adds :not_present_workplace error' do
          subject.invalid?

          expect(subject.errors.details[:base]).to include(error: :not_present_workplace, workplace_id: subject.invent_workplace_id)
        end
      end

      context 'when the item was not found at the workplace' do
        before { subject.invent_num = subject.invent_num.to_i + 1 }

        it 'adds :item_not_find_on_workplace error' do
          subject.invalid?

          expect(subject.errors.details[:base]).to include(error: :item_not_find_on_workplace, workplace_id: subject.invent_workplace_id)
        end
      end
    end

    describe '#check_absent_warehouse_items_for_inv_item' do
      let(:warehouse_item) do
        w_item = build(:new_item, warehouse_type: :without_invent_num, item_type: 'картридж', item_model: '6515DNI', count: 1)
        w_item.build_barcode_item

        w_item.save
        w_item
      end
      let(:inv_item) do
        i_item = build(:item, :with_property_values, type_name: :printer, warehouse_items: [warehouse_item])
        i_item.save(validate: false)
        i_item
      end
      let(:operation) { build(:order_operation, inv_items: [inv_item], status: 'done') }
      let(:workplace) do
        w = build(:workplace_net_print, items: [inv_item])
        w.save(validate: false)
        w
      end

      subject { build(:order, operations: [operation], inv_workplace: workplace) }

      before { subject.execute_in = true }

      it 'adds :warehouse_items_is_present error' do
        subject.valid?

        expect(subject.errors.details[:base]).to include(error: :warehouse_items_is_present, arr_type_with_barcode: warehouse_item.item_type.to_s)
      end

      context 'when operation status ins processing' do
        before { operation.status = 'processing' }

        it { is_expected.to be_valid }
      end
    end

    # context 'when operation is :in' do
    #   before { subject.dont_calculate_status = true }

    #   context 'and when status is done' do
    #     subject { build(:order, operation: :in, status: :done) }

    #     it { is_expected.to validate_presence_of(:consumer_dept) }
    #   end

    #   context 'and when status is not done' do
    #     subject { build(:order, operation: :in, status: :processing) }

    #     it { is_expected.not_to validate_presence_of(:consumer_dept) }
    #   end
    # end

    describe '#any_inv_item_to_operation?' do
      context 'when operation has inv_item_to_operations' do
        let(:item) { create(:item, :with_property_values, type_name: :monitor) }
        let(:operation) { build(:order_operation, inv_items: [item]) }
        subject { build(:order, operations: [operation]) }

        it 'return true' do
          expect(subject.any_inv_item_to_operation?).to be_truthy
        end
      end

      context 'when operation does not have inv_item_to_operations' do
        it 'returns false' do
          expect(subject.any_inv_item_to_operation?).to be_falsey
        end
      end
    end

    describe '#any_w_item_have_inv_item?' do
      let(:inv_item) do
        i_item = build(:item, :with_property_values, type_name: :printer)
        i_item.save(validate: false)
        i_item
      end
      let(:warehouse_item) do
        w_item = build(:new_item, warehouse_type: :without_invent_num, item_type: 'картридж', item_model: '6515DNI', count: 1)
        w_item.build_barcode_item
        w_item.item = inv_item

        w_item.save(validate: false)
        w_item
      end
      let(:operation) { build(:order_operation, item_id: warehouse_item.id) }

      subject { build(:order, operations: [operation]) }

      it 'returns true' do
        expect(subject.any_w_item_have_inv_item?).to be_truthy
      end

      context 'when warehouse_item is not associated with inv_item' do
        before { warehouse_item.item = nil }

        it 'return false' do
          expect(subject.any_w_item_have_inv_item?).to be_falsey
        end
      end
    end

    context 'when operation is :write_off' do
      let(:operation) { build(:order_operation, item: item) }
      subject { build(:order, operation: :write_off, operations: [operation]) }

      context 'and when item is new' do
        let(:item) { create(:new_item) }

        it 'adds :order_must_contains_only_used_items error' do
          subject.valid?

          expect(subject.errors.details[:base]).to include(error: :order_must_contains_only_used_items)
        end
      end

      context 'and when item is used' do
        let(:item) { create(:used_item) }

        it { is_expected.to be_valid }
      end
    end

    describe '#consumer_from_history' do
      context 'when consumer_fio is empty' do
        let(:result) do
          {
            id_tn: 123,
            fio: 'Тест ФИО'
          }
        end
        before do
          subject.consumer_id_tn = 123
          subject.consumer_fio = 'Тест ФИО'
        end

        it 'creates object with :id_tn and :fio attributes' do
          expect(subject.consumer_from_history).to eq result
        end
      end

      context 'when consumer_fio is filled' do
        before do
          subject.consumer_id_tn = nil
          subject.consumer_fio = nil
        end

        its(:consumer_from_history) { is_expected.to be_nil }
      end
    end

    describe '#find_inv_item_for_assign_barcode' do
      let(:workplace) { create(:workplace_net_print, :add_items, items: %i[printer]) }
      subject { build(:order, inv_workplace: workplace, operation: :out, invent_num: workplace.items.first.invent_num) }

      it 'retutns item in wrap array' do
        expect(subject.find_inv_item_for_assign_barcode).to eq [workplace.items.first]
      end

      context 'when workplace is blank' do
        before { subject.invent_workplace_id = nil }

        it 'returns is blank array' do
          expect(subject.find_inv_item_for_assign_barcode).to eq []
        end
      end
    end

    describe '#presence_consumer' do
      before { subject.valid? }

      %i[in out].each do |op|
        context "when order operation is :#{op}" do
          subject { build(:order, operation: op, operations: operations) }

          context 'and when one of operations status is done' do
            let(:operations) { [build(:order_operation, status: :done), build(:order_operation)] }

            it 'adds error :blank to the consumer' do
              expect(subject.errors.details[:consumer]).to include(error: :blank)
            end
          end

          context 'and when all of operations status is processing' do
            let(:operations) { [build(:order_operation), build(:order_operation)] }

            it 'does not add error :blank to the consumer' do
              expect(subject.errors.details[:consumer]).to be_empty
            end
          end
        end
      end

      context 'when order operation is :write_off' do
        subject { build(:order, operation: :write_off, operations: operations) }
        let!(:item_1) { create(:used_item) }
        let!(:item_2) { create(:used_item) }

        context 'and when one of operations status is done' do
          let(:operations) { [build(:order_operation, status: :done, item: item_1), build(:order_operation, item: item_2)] }

          it 'does not add error :blank to the consumer' do
            expect(subject.errors.details[:consumer]).to be_empty
          end
        end

        context 'and when all of operations status is processing' do
          let(:operations) { [build(:order_operation, item: item_1), build(:order_operation, item: item_2)] }

          it 'does not add error :blank to the consumer' do
            expect(subject.errors.details[:consumer]).to be_empty
          end
        end
      end
    end

    describe '#uniqueness_of_workplace' do
      let!(:workplace_1) { create(:workplace_pk, :add_items, items: %i[pc monitor], dept: ***REMOVED***) }
      let!(:workplace_2) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }

      context 'when items belongs to the different workplaces' do
        let(:operations) do
          [
            build(:order_operation, inv_items: [workplace_1.items.first]),
            build(:order_operation, inv_items: [workplace_2.items.first])
          ]
        end
        # let(:ids) { [workplace_1.items.first.item_id, workplace_2.items.first.item_id] }
        subject { build(:order, operations: operations) }

        it 'adds :uniq_workplace error' do
          subject.valid?

          expect(subject.errors.details[:base]).to include(error: :uniq_workplace)
        end

        context 'and when present item with barcode and type :without_invent_num' do
          let(:workplace_3) do
            w = build(:workplace_net_print)
            w.save(validate: false)
            w
          end
          let(:inv_item) do
            i_item = build(:item, :with_property_values, type_name: :printer)
            i_item.workplace = workplace_3
            i_item.save(validate: false)
            i_item
          end
          let(:warehouse_item) do
            w_item = build(:new_item, warehouse_type: :without_invent_num, item_type: 'картридж', item_model: '6515DNI', count: 1)
            w_item.build_barcode_item
            w_item.item = inv_item

            w_item.save(validate: false)
            w_item
          end
          let(:operation) { build(:order_operation, item_id: warehouse_item.id) }

          before { operations << operation }

          it 'adds :uniq_workplace error' do
            subject.valid?

            expect(subject.errors.details[:base]).to include(error: :uniq_workplace)
          end
        end

        it { is_expected.not_to be_valid }

        context 'and when for one operation the status changes :done' do
          let(:user) { create(:***REMOVED***_user)}
          before do
            operations.first.status = 'done'
            operations.first.stockman_fio = user.fullname
            subject.consumer_fio = user.fullname
          end

          it { is_expected.to be_valid }
        end
      end

      context 'when items belongs to the same workplace' do
        let(:operation_1) { build(:order_operation, inv_items: [workplace_1.items.first]) }
        let(:operation_2) { build(:order_operation, inv_items: [workplace_1.items.last]) }
        subject { build(:order, inv_workplace: workplace_1, operations: [operation_1, operation_2]) }

        it { is_expected.to be_valid }
      end

      context 'when one of item does not have workplace' do
        let(:operations) do
          [
            build(:order_operation, inv_items: [workplace_1.items.first]),
            build(:order_operation, inv_items: [workplace_1.items.last])
          ]
        end
        subject { build(:order, inv_workplace: workplace_1, operations: operations) }
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

        it 'sets current time to the :closed_time attribute' do
          subject.save
          expect(subject.closed_time).not_to be_nil
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
              expect(subject.send("consumer_#{attr}")).to eq user_iss.send(attr)
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
        let(:tn) { 24_079 }
        let(:new_user) { UserIss.find_by(fio: fio) }
        let(:old_user) { UserIss.find_by(tn: tn) }

        context 'and when consumer_id_tn already exists' do
          subject { build(:order, consumer_tn: tn, consumer_fio: fio) }

          it 'does not load a new id_tn from the UserIss table' do
            subject.save
            expect(subject.consumer_id_tn).to eq old_user.id_tn
          end
        end

        context 'and when consumer_id_tn is blank' do
          subject { build(:order, consumer_fio: fio) }

          it 'loads id_tn from the UserIss table' do
            subject.save
            expect(subject.consumer_id_tn).to eq new_user.id_tn
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

      context 'when exists consumer' do
        let(:user_iss) { UserIss.find_by(tn: ***REMOVED***) }
        subject { build(:order, consumer: user_iss) }

        it 'sets consumer_fio' do
          subject.save
          expect(subject.consumer_fio).to eq user_iss.fio
        end
      end
    end

    describe '#set_closed_time' do
      context 'when status is :done' do
        let(:date) { Time.zone.now }
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

    describe '#set_workplace_inv_items' do
      let!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor], dept: ***REMOVED***) }
      let(:operations) do
        [
          build(:order_operation, inv_items: [workplace.items.first]),
          build(:order_operation, inv_items: [workplace.items.last])
        ]
      end

      context 'when operation is :in' do
        subject { build(:order, operations: operations) }

        it 'sets :workplace attribute' do
          expect { subject.valid? }.to change(subject, :invent_workplace_id).to(workplace.workplace_id)
        end
      end

      context 'when operation is :out' do
        subject { build(:order, operation: :out, operations: operations) }

        it 'does not set :workplace attribute' do
          expect { subject.valid? }.not_to change(subject, :invent_workplace_id)
        end
      end
    end

    describe '#set_workplace_w_item' do
      let(:warehouse_item) do
        w_item = build(:new_item, warehouse_type: :without_invent_num, item_type: 'картридж', item_model: '6515DNI', count: 1)
        w_item.build_barcode_item

        w_item.save
        w_item
      end
      let(:inv_item) do
        i_item = build(:item, :with_property_values, type_name: :printer, warehouse_items: [warehouse_item])
        i_item.save(validate: false)
        i_item
      end
      let(:operation) { build(:order_operation, inv_items: [inv_item], item_id: warehouse_item.id) }
      let(:workplace) do
        w = build(:workplace_net_print, items: [inv_item])
        w.save(validate: false)
        w
      end

      subject { build(:order, operations: [operation], inv_workplace: workplace) }

      it 'assigned invent_workplace_id for order' do
        subject.valid?

        expect(subject.invent_workplace_id).to eq inv_item.workplace_id
      end
    end

    describe '#set_consumer_dept_out' do
      let!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor], dept: ***REMOVED***) }

      context 'when operation is :in' do
        context 'and when item with invent_num' do
          subject { build(:order, inv_workplace: workplace, consumer_dept: nil) }

          it 'gets consumer_dept from WorkplaceCount' do
            subject.valid?
            expect(subject.consumer_dept).to eq workplace.division
          end
        end

        context 'and when item without invent_num' do
          subject { build(:order, inv_workplace: nil, consumer_tn: 12_321, consumer_dept: nil) }

          it 'gets consumer_dept from UserIss' do
            subject.valid?
            expect(subject.consumer_dept).to eq subject.consumer.dept.to_s
          end
        end
      end

      context 'when operation is :out' do
        subject { build(:order, operation: :out, inv_workplace: workplace, consumer_dept: nil) }

        it 'sets :consumer_dept attribute' do
          subject.valid?
          expect(subject.consumer_dept).to eq workplace.workplace_count.division
        end
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

    describe '#set_validator' do
      before { subject.set_validator(user) }

      context 'when user exists' do
        let(:user) { create(:user) }

        it 'sets creator_id_tn' do
          expect(subject.validator_id_tn).to eq user.id_tn
        end

        it 'sets creator_fio' do
          expect(subject.validator_fio).to eq user.fullname
        end
      end

      context 'when user is nil' do
        let(:user) { nil }

        it 'sets nil to creator_id_tn' do
          expect(subject.validator_id_tn).to be_nil
        end

        it 'sets nil to creator_fio' do
          expect(subject.validator_fio).to be_nil
        end
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
          order_json['operations_attributes'].each { |op| op['_destroy'] = 1 }

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
        let(:operations) { [build(:order_operation, inv_items: workplace.items)] }
        subject { build(:order, inv_workplace: workplace, operations: operations) }

        it 'adds :nested_arrs_not_equals error' do
          subject.valid?
          expect(subject.errors.details[:base]).to include(error: :nested_arrs_not_equals)
        end
      end
    end

    # describe '#compare_consumer_dept' do
    #   context 'when consumer_dept does not match with division of the selected item' do
    #     let!(:workplace_***REMOVED***) { create(:workplace_pk, :add_items, items: %i[pc monitor], dept: ***REMOVED***) }
    #     let!(:workplace_***REMOVED***) { create(:workplace_pk, :add_items, items: %i[pc monitor], dept: ***REMOVED***) }
    #     let(:operations) {
    #       [
    #         build(:order_operation, inv_items: [workplace_***REMOVED***.items.last]),
    #         build(:order_operation, inv_items: [workplace_***REMOVED***.items.last])
    #       ]
    #     }
    #     subject { build(:order, operations: operations, consumer_dept: ***REMOVED***) }

    #     it { is_expected.not_to be_valid }

    #     it 'adds :dept_does_not_match error' do
    #       subject.valid?
    #       expect(subject.errors.details[:base]).to include(error: :dept_does_not_match, dept: subject.consumer_dept)
    #     end
    #   end

    #   context 'when inv_item already does not have workplace_id (workplace was removed?)' do
    #     let(:item) { create(:item, :with_property_values, type_name: :monitor) }
    #     let(:operation) { build(:order_operation, inv_items: [item]) }
    #     subject { build(:order, operations: [operation], consumer_dept: ***REMOVED***) }

    #     it 'does not add :dept_does_not_match error' do
    #       subject.valid?
    #       expect(subject.errors.details[:base]).not_to include(error: :dept_does_not_match, dept: subject.consumer_dept)
    #     end
    #   end
    # end

    describe '#check_operation_shift' do
      context 'when one of operations :shift attribtue is not equal 1' do
        let(:operations) { [build(:order_operation), build(:order_operation, shift: 2)] }
        subject { build(:order, operations: operations) }

        it 'adds :shift_must_be_equal_1 error' do
          subject.valid?
          expect(subject.errors.details[:base]).to include(error: :shift_must_be_equal_1)
        end
      end

      context 'when all operations :shift attribtue is equal 1' do
        let(:operations) { [build(:order_operation), build(:order_operation)] }
        subject { build(:order, operations: operations) }

        it { is_expected.to be_valid }
      end
    end

    describe '#check_operation_list' do
      let(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
      before { subject.operations << new_operation }

      context 'when warehouse_type of items is :without_invent_num (workplace is not exist)' do
        let(:old_operation) { build(:order_operation, item_type: 'Клавиатура', item_model: 'OKLICK') }
        let(:new_operation) { build(:order_operation, inv_items: [workplace.items.first]) }
        subject { create(:order, operations: [old_operation]) }

        it 'not allow to add to the operations any items with inv_items' do
          subject.valid?
          expect(subject.errors.details[:base]).to include(error: :cannot_have_operations_with_invent_num)
        end
      end

      context 'when warehouse_type of items is :with_invent_num (workplace is exists)' do
        let(:old_operation) { build(:order_operation, inv_items: [workplace.items.first]) }
        subject { create(:order, inv_workplace: workplace, operations: [old_operation]) }

        context 'and when add operations without inv_items' do
          let(:new_operation) { build(:order_operation, item_type: 'Клавиатура', item_model: 'OKLICK') }

          it 'adds :cannot_have_operations_without_invent_num error' do
            subject.valid?
            expect(subject.errors.details[:base]).to include(error: :cannot_have_operations_without_invent_num)
          end
        end

        context 'and whem add operations with inv_items' do
          let(:new_operation) { build(:order_operation, inv_items: [workplace.items.last]) }

          it { is_expected.to be_valid }
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
      let(:workplace) { create(:workplace_pk, :add_items, items: %i[monitor pc]) }
      subject { create(:order, consumer_id_tn: user.id_tn, inv_workplace: workplace) }
      let!(:old_params) do
        {
          invent_workplace_id: subject.invent_workplace_id,
          operation: subject.operation,
          consumer_dept: subject.consumer_dept
        }
      end

      it 'prevents changes of :workplace attribute' do
        subject.invent_workplace_id = 123
        subject.save(validate: false)

        expect(subject.reload.invent_workplace_id).to eq old_params[:invent_workplace_id]
        expect(subject.errors.details[:inv_workplace]).to include(error: :cannot_update)
      end

      it 'prevents changes of :operation attribute' do
        subject.operation = :out
        subject.save(validate: false)

        expect(subject.reload.operation).to eq old_params[:operation]
        expect(subject.errors.details[:operation]).to include(error: :cannot_update)
      end

      it 'prevents changes of :consumer_dept attribute' do
        subject.consumer_dept = 123
        subject.save(validate: false)

        expect(subject.reload.consumer_dept).to eq old_params[:consumer_dept]
        expect(subject.errors.details[:consumer_dept]).to include(error: :cannot_update)
      end
    end
  end
end
