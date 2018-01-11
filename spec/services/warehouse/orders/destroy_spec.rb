require 'rails_helper'

module Warehouse
  module Orders
    RSpec.describe Destroy, type: :model do
      let!(:order) { create(:order) }
      subject { Destroy.new(order.warehouse_order_id) }

      its(:run) { is_expected.to be_truthy }

      it 'destroys selected order' do
        expect { subject.run }.to change(Order, :count).by(-1)
      end

      context 'when order is not destroyed' do
        before { allow_any_instance_of(Order).to receive(:destroy).and_return(false) }

        its(:run) { is_expected.to be_falsey }
      end
    end
  end
end
