require 'feature_helper'

module Warehouse
  module Items
    RSpec.describe Destroy, type: :model do
      let!(:item) { create(:new_item) }
      subject { Destroy.new(item.id) }

      its(:run) { is_expected.to be_truthy }

      it 'destroys selected order' do
        expect { subject.run }.to change(Item, :count).by(-1)
      end

      context 'when order is not destroyed' do
        before { allow_any_instance_of(Item).to receive(:destroy).and_return(false) }

        its(:run) { is_expected.to be_falsey }
      end
    end
  end
end
