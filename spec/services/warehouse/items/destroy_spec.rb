require 'feature_helper'

module Warehouse
  module Items
    RSpec.describe Destroy, type: :model do
      let(:user) { create(:user) }
      let!(:item) { create(:new_item) }
      subject { Destroy.new(user, item.id) }

      its(:run) { is_expected.to be_truthy }

      it 'destroys selected item' do
        expect { subject.run }.to change(Item, :count).by(-1)
      end

      it 'broadcasts to items' do
        expect(subject).to receive(:broadcast_items)
        subject.run
      end

      context 'when order is not destroyed' do
        before { allow_any_instance_of(Item).to receive(:destroy).and_return(false) }

        its(:run) { is_expected.to be_falsey }
      end
    end
  end
end
