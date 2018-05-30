require 'feature_helper'

module Warehouse
  module Orders
    RSpec.describe ConfirmOut, type: :model do
      let(:manager) { create(:***REMOVED***_user) }
      subject { ConfirmOut.new(manager, order.id) }

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
        let!(:order) { create(:order) }

        its(:run) { is_expected.to be_falsey }
      end
    end
  end
end
