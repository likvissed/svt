require 'feature_helper'

module Warehouse
  module Orders
    RSpec.describe Confirm, type: :model do
      before do
        allow_any_instance_of(Order).to receive(:find_employee_by_workplace).and_return([build(:emp_***REMOVED***)])
        allow_any_instance_of(Order).to receive(:set_consumer_dept_in)
      end

      let(:manager) { create(:***REMOVED***_user) }
      subject { Confirm.new(manager, order.id) }

      context 'when :operation attribute is "out"' do
        let!(:order) { create(:order, operation: :out) }
        its(:run) { is_expected.to be_truthy }

        it 'sets a validator data' do
          subject.run
          expect(order.reload.validator_id_tn).to eq manager.id_tn
          expect(order.reload.validator_fio).to eq manager.fullname
        end

        it 'broadcasts to out_orders' do
          expect(subject).to receive(:broadcast_out_orders)
          subject.run
        end
      end

      context 'when :operation attribute is "in"' do
        let!(:order) { create(:order, operation: :in) }
        its(:run) { is_expected.to be_truthy }

        it 'sets a validator data' do
          subject.run
          expect(order.reload.validator_id_tn).to eq manager.id_tn
          expect(order.reload.validator_fio).to eq manager.fullname
        end

        it 'broadcasts to in_orders' do
          expect(subject).to receive(:broadcast_in_orders)
          subject.run
        end
      end

      context 'when :operation attribute is "write_off"' do
        let!(:order) { create(:order, operation: :write_off) }
        its(:run) { is_expected.to be_truthy }

        it 'sets a validator data' do
          subject.run
          expect(order.reload.validator_id_tn).to eq manager.id_tn
          expect(order.reload.validator_fio).to eq manager.fullname
        end

        it 'broadcasts to write_off_orders' do
          expect(subject).to receive(:broadcast_write_off_orders)
          subject.run
        end
      end
    end
  end
end
