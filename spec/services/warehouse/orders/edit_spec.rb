require 'rails_helper'

module Warehouse
  module Orders
    RSpec.describe Edit, type: :model do
      let(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
      let!(:order) { create(:order, workplace: workplace) }
      subject { Edit.new(order.warehouse_order_id) }
      before { subject.run }

      it 'fills the @data with %i[order divisions users eq_types order] keys' do
        expect(subject.data).to include(:order, :divisions, :users, :eq_types, :order)
      end

      it 'adds item_to_orders_attributes to order' do
        expect(subject.data[:order]).to include('item_to_orders_attributes')
      end

      it 'loads all item_to_orders attributes' do
        expect(subject.data[:order]['item_to_orders_attributes'].count).to eq order.item_to_orders.count
      end

      it 'replaces primary_key with id param' do
        expect(subject.data[:order]['item_to_orders_attributes'].first['id']).to eq order.item_to_orders.first.warehouse_item_to_order_id
      end
    end
  end
end
