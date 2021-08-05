require 'feature_helper'

module Warehouse
  RSpec.describe Operation, type: :model do
    it { is_expected.to have_many(:inv_item_to_operations).dependent(:destroy) }
    it { is_expected.to have_many(:inv_items).through(:inv_item_to_operations).class_name('Invent::Item') }
    it { is_expected.to belong_to(:item).optional }
    it { is_expected.to belong_to(:operationable) }
    it { is_expected.to validate_presence_of(:item_type) }
    it { is_expected.to validate_presence_of(:item_model) }
    it { is_expected.to validate_presence_of(:shift) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.not_to validate_presence_of(:stockman_fio) }
    it { is_expected.not_to validate_presence_of(:date) }
    it { is_expected.to accept_nested_attributes_for(:inv_items).allow_destroy(false) }
    skip_users_reference

    before do
      allow_any_instance_of(Order).to receive(:set_consumer_dept_in)
      allow_any_instance_of(Order).to receive(:find_employee_by_workplace).and_return([build(:emp_***REMOVED***)])
    end
    let(:order) { create(:order) }

    context 'when :shift attribute is equal zero' do
      subject { build(:supply_operation, shift: 0) }

      it 'adds :other_than error' do
        subject.valid?
        expect(subject.errors.details[:shift]).to include(error: :other_than, value: 0, count: 0)
      end
    end

    context 'when status is done' do
      subject { build(:order_operation, status: :done) }

      it { is_expected.to validate_presence_of(:stockman_fio) }
      # it { is_expected.to validate_presence_of(:date) }
    end

    describe '#set_stockman' do
      let(:user) { create(:user) }
      before { subject.set_stockman(user) }

      it 'sets stockman_id_tn' do
        expect(subject.stockman_id_tn).to eq user.id_tn
      end

      it 'sets stockman_fio' do
        expect(subject.stockman_fio).to eq user.fullname
      end
    end

    describe '#build_inv_items' do
      subject { create(:order_operation, item: item, shift: -2, operationable: order) }

      context 'when :warehouse_type attribute of item has :without_invent_num value' do
        let(:item) { create(:new_item, warehouse_type: :without_invent_num) }

        it 'returns nil' do
          expect(subject.build_inv_items(subject.shift.abs)).to be_nil
        end
      end

      context 'when :warehouse_type attribute of item has :with_invent_num value' do
        let(:status) { 'waiting_take' }

        context 'and when inv_item exists' do
          let!(:workplace_1) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
          let!(:workplace_2) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
          let!(:item) { create(:used_item, inv_item: workplace_1.items.first) }

          it 'change inv_item params' do
            subject.build_inv_items(subject.shift.abs, workplace: workplace_2, status: status)

            subject.inv_items.each do |inv_item|
              expect(inv_item.workplace).to eq workplace_2
              expect(inv_item.status).to eq status
            end
          end

          it 'barcode for item is present' do
            subject.inv_items.each { |inv_item| expect(inv_item.barcode_item).to exist }
          end
        end

        context 'and when inv_item is not exist' do
          let(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
          let(:type) { Invent::Type.find_by(name: :monitor) }
          let(:item) { create(:new_item, inv_type: type, inv_model: type.models.first, count: 2, invent_num_end: 112) }
          before { subject.build_inv_items(subject.shift.abs, workplace: workplace, status: status) }

          it 'builds inv_items' do
            expect(subject.inv_items.size).to eq subject.shift.abs
            subject.inv_items.each_with_index do |inv_item, index|
              expect(inv_item.type).to eq item.inv_type
              expect(inv_item.workplace).to eq workplace
              expect(inv_item.model).to eq item.inv_model
              expect(inv_item.invent_num.to_i).to eq item.invent_num_start + index
              expect(inv_item.status).to eq status
              expect(inv_item.property_values.size).to eq item.inv_type.properties.size
            end
          end

          # it 'builds invent_nums' do
          #   expect(subject.item.invent_nums.size).to eq subject.inv_items.size
          # end
        end
      end
    end

    describe '#calculate_item_count_reserved (for :out operation)' do
      let(:item) { create(:new_item, warehouse_type: :without_invent_num, count: 20) }

      context 'when operation is a new record' do
        subject { build(:order_operation, item: item, shift: -4, operationable: order) }

        it 'increased :count_reserved attribute' do
          subject.calculate_item_count_reserved

          expect(item.count_reserved).to eq subject.shift.abs
        end
      end

      context 'when operation already exists' do
        let(:item) { create(:new_item, warehouse_type: :without_invent_num, count: 20, count_reserved: 15) }
        subject { create(:order_operation, item: item, shift: -4, operationable: order) }

        context 'and when operation marked for destruction' do
          before { subject.mark_for_destruction }

          it 'reduced :count_reserved attribute' do
            subject.calculate_item_count_reserved

            expect(item.count_reserved).to eq 11
          end
        end

        context 'and when :shift attribute is increased' do
          before { subject.shift = -3 }

          it 'reduced :count_reserved attribute' do
            subject.calculate_item_count_reserved

            expect(item.count_reserved).to eq 14
          end
        end

        context 'and when :shift attribute is reduced' do
          before { subject.shift = -6 }

          it 'increased :count_reserved attribute' do
            subject.calculate_item_count_reserved

            expect(item.count_reserved).to eq 17
          end
        end

        context 'when status of operation changed to :done' do
          before { subject.status = :done }

          it 'reduced :count_reserved attribute' do
            subject.calculate_item_count_reserved

            expect(item.count_reserved).to eq 11
          end
        end
      end
    end

    describe '#calculate_item_count' do
      let!(:item) { create(:new_item, warehouse_type: :without_invent_num, count: 20) }

      context 'with supply operation' do
        context 'and when operation is a new record' do
          subject { build(:supply_operation, item: item, shift: 4, operationable: order) }

          it 'increased :count_reserved attribute' do
            subject.calculate_item_count
            expect(item.count).to eq 24
          end
        end

        context 'and when operation already exists' do
          subject { create(:supply_operation, item: item, shift: 4, operationable: order) }

          context 'and when operation marked for destruction' do
            before { subject.mark_for_destruction }

            it 'reduced :count attribute' do
              subject.calculate_item_count

              expect(item.count).to eq 16
            end
          end

          context 'and when :shift attribute is increased' do
            before { subject.shift = 7 }

            it 'reduced :count attribute' do
              subject.calculate_item_count

              expect(item.count).to eq 23
            end
          end

          context 'and when :shift attribute is reduced' do
            before { subject.shift = 2 }

            it 'increased :count attribute' do
              subject.calculate_item_count

              expect(item.count).to eq 18
            end
          end
        end
      end

      context 'and with order operation and when status of operation changed to :done' do
        let!(:user) { create(:***REMOVED***_user) }
        let(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }

        context 'and when operation is :in' do
          let(:item) { workplace.items.first }
          let(:operation) { attributes_for(:order_operation, inv_item_ids: [item.item_id]) }
          before do
            operation = attributes_for(:order_operation, inv_item_ids: [item.item_id])
            order_params = attributes_for(:order, operation: :in, invent_workplace_id: workplace.workplace_id, operations_attributes: [operation])
            Orders::CreateIn.new(user, order_params.as_json).run
          end
          subject { Operation.last }

          it 'increased :count attribute' do
            subject.status = :done
            subject.calculate_item_count

            expect(subject.item.count).to eq 1
          end
        end

        context 'and when operation is :out' do
          let(:order) { create(:order, operation: :out, inv_workplace: workplace) }
          subject { create(:order_operation, item: item, shift: -4, operationable: order) }
          before { subject.status = :done }

          it 'reduced :count attribute' do
            subject.calculate_item_count

            expect(item.count).to eq 16
          end
        end
      end
    end

    describe '#calculate_item_invent_num_end' do
      let!(:item) { build(:new_item, warehouse_type: :with_invent_num, count: 0, invent_num_start: 765_100) }

      context 'when operation is a new record' do
        subject { build(:supply_operation, item: item, shift: 25, operationable: order) }

        it 'calculate :invent_num_end attribute' do
          subject.calculate_item_invent_num_end

          expect(item.invent_num_end).to eq 765_124
        end
      end

      context 'when operation already exists' do
        subject { create(:supply_operation, item: item, shift: 4, operationable: order) }

        context 'and when operation marked for destruction' do
          before { subject.mark_for_destruction }

          it 'reduced :invent_num_end attribute' do
            subject.calculate_item_invent_num_end

            expect(item.invent_num_end).to eq 765_100
          end
        end

        context 'and when :shift attribute is increased' do
          before { subject.shift = 6 }

          it 'reduced :invent_num_end attribute' do
            subject.calculate_item_invent_num_end

            expect(item.invent_num_end).to eq 765_105
          end
        end

        context 'and when :shift attribute is reduced' do
          before { subject.shift = 2 }

          it 'increased :invent_num_end attribute' do
            subject.calculate_item_invent_num_end

            expect(item.invent_num_end).to eq 765_101
          end
        end
      end

      context 'when invent_num_start was changed' do
        let!(:item) do
          i = build(:new_item, warehouse_type: :with_invent_num, count: 0, invent_num_start: nil, invent_num_end: nil)
          i.save(validate: false)
          i
        end
        subject do
          s = build(:supply_operation, item_id: item.id, shift: 25, skip_calculate_invent_nums: true)
          s.save(validate: false)
          s
        end
        before { subject.item.invent_num_start = 101 }

        it 'calculates a new :invent_num_end attribute' do
          subject.calculate_item_invent_num_end

          expect(subject.item.invent_num_end).to eq 125
        end
      end

      context 'when invent_num_start is null' do
        let!(:item) do
          i = build(:new_item, warehouse_type: :with_invent_num, count: 0, invent_num_start: nil, invent_num_end: nil)
          i.save(validate: false)
          i
        end
        subject { build(:supply_operation, item_id: item.id, shift: 25) }

        it 'does not calculate invent_num_end' do
          subject.calculate_item_invent_num_end

          expect(subject.item.invent_num_end).to be_nil
        end
      end
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
      context 'when item type is :with_ivnent_num' do
        context 'and when operation with :processing status for specified item is not exist' do
          let(:item) { create(:item, :with_property_values, type_name: :monitor) }
          let(:used_item) { create(:used_item, inv_item: item) }
          subject { build(:order_operation, item: used_item, operationable: order) }

          it { is_expected.to be_valid }
        end

        context 'and when operation with :processing status for specified item exists' do
          let(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor monitor]) }
          let(:inv_item) { workplace.items.first }
          let(:used_item) { create(:used_item, inv_item: inv_item) }
          let(:operation) { build(:order_operation, inv_items: [inv_item], item: used_item) }
          let!(:order) { create(:order, inv_workplace: workplace, operations: [operation]) }
          subject { build(:order_operation, item: order.items.first, operationable: order) }

          it 'adds :operation_already_exists error' do
            subject.valid?

            expect(subject.errors.details[:base]).to include(
              error: :operation_with_invent_num_already_exists,
              type: used_item.item_type,
              invent_num: inv_item.invent_num,
              order_id: order.id
            )
          end
        end
      end

      context 'when item type is :without_ivnent_num' do
        context 'and when operation with :processing status for specified item is not exist' do
          let(:used_item) { create(:used_item, item_type: 'test', item_model: 'test', warehouse_type: :without_invent_num, count: 1) }
          subject { build(:order_operation, item: used_item, operationable: order) }

          it { is_expected.to be_valid }
        end

        context 'and when operation with :processing status for specified item exists' do
          let(:used_item) { create(:used_item, item_type: 'test', item_model: 'test', warehouse_type: :without_invent_num, count: 1) }
          let(:operation) { build(:order_operation, item: used_item) }
          let!(:order) { create(:order, operations: [operation]) }
          subject { build(:order_operation, item: order.items.first) }

          it 'adds :operation_already_exists error' do
            subject.valid?

            expect(subject.errors.details[:base]).to include(
              error: :operation_without_invent_num_already_exists,
              type: used_item.item_type,
              model: used_item.item_model,
              order_id: order.id
            )
          end
        end
      end
    end

    describe '#set_date' do
      let!(:date) { Time.zone.now }
      before { allow(Time).to receive(:now).and_return(date) }

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

    describe '#prevent_change_status' do
      context 'when status was done and changed to :processing' do
        let(:user) { create(:user) }
        subject { create(:order_operation, status: :done, stockman_id_tn: user.id_tn, operationable: order) }
        before do
          subject.status = 'processing'
          subject.save
        end

        it 'adds :cannot_cancel_done_operation error' do
          expect(subject.errors.details[:base]).to include(error: :cannot_cancel_done_operation)
        end

        it 'does not change status' do
          expect(Operation.last.done?).to be_truthy
        end
      end
    end

    describe '#prevent_update' do
      let(:user) { create(:user) }
      subject { create(:order_operation, status: :done, stockman_id_tn: user.id_tn, operationable: order) }

      context 'when status is done and another attribute was changed' do
        let(:new_user) { create(:***REMOVED***_user) }
        before { subject.set_stockman(new_user) }

        include_examples ':cannot_update_done_operation error'
      end
    end

    describe '#prevent_destroy' do
      let(:user) { create(:user) }
      let!(:operation) { create(:order_operation, status: :done, stockman_id_tn: user.id_tn, operationable: order) }

      it 'does not destroy operation' do
        expect { operation.destroy }.not_to change(Operation, :count)
      end

      it 'adds :cannot_destroy_done_operation error' do
        operation.destroy
        expect(operation.errors.details[:base]).to include(error: :cannot_destroy_done_operation)
      end
    end

    describe '#presence_warehouse_receiver_fio' do
      let(:order) { create(:order, operation: :out) }
      let(:user) { create(:user) }
      let(:new_item) { create(:new_item) }
      subject { create(:order_operation, status: :done, stockman_id_tn: user.id_tn, operationable: order, item: new_item) }
      before { subject.presence_w_receiver_fio = true }

      it 'adds :blank error for warehouse_receiver_fio' do
        subject.valid?

        expect(subject.errors.details[:warehouse_receiver_fio]).to include(error: :blank)
      end
    end

    describe '#check_worker_w_receiver_fio' do
      let(:user) { create(:user) }
      let(:new_item) { create(:new_item) }
      subject { create(:order_operation, status: :done, stockman_id_tn: user.id_tn, operationable: order, item: new_item) }
      before do
        subject.worker_w_receiver_fio = true
        subject.warehouse_receiver_fio = 'Example FIO'
      end

      it 'adds :denied_access_for_assign_receiver_fio error' do
        subject.valid?

        expect(subject.errors.details[:base]).to include(error: :denied_access_for_assign_receiver_fio, item_type: subject.item.item_type)
      end
    end
  end
end
