require 'feature_helper'

module Invent
  module Items
    RSpec.describe ToStock, type: :model do
      let!(:user) { create(:user) }
      let(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor] ) }
      let!(:item) { workplace.items.first }
      let(:create_by_inv_item) { Warehouse::Orders::CreateByInvItem.new(user, item) }
      subject { ToStock.new(user, item.item_id) }

      before { allow(Warehouse::Orders::CreateByInvItem).to receive(:new).and_return(create_by_inv_item) }
      it 'creates Warehouse::Orders::CreateByInvItem instance' do
        expect(Warehouse::Orders::CreateByInvItem).to receive(:new).with(user, item)
        subject.run
      end

      it 'runs :run method for Warehouse::Orders::CreateByInvItem instance' do
        expect(create_by_inv_item).to receive(:run).and_return(true)
        subject.run
      end
    end
  end
end
