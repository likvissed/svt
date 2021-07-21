require 'feature_helper'

module Invent
  module Items
    RSpec.describe Destroy, type: :model do
      skip_users_reference

      let(:user) { create(:user) }
      let!(:item) { create(:item, :with_property_values, type_name: :monitor) }
      subject { Destroy.new(user, item.item_id) }

      its(:run) { is_expected.to be_truthy }

      it 'destroys item' do
        expect { subject.run }.to change(Item, :count).by(-1)
      end

      it 'broadcasts to items' do
        expect(subject).to receive(:broadcast_items)
        subject.run
      end

      context 'when item was not destroyed' do
        before { allow_any_instance_of(Item).to receive(:destroy).and_return(false) }

        its(:run) { is_expected.to be_falsey }
      end
    end
  end
end
