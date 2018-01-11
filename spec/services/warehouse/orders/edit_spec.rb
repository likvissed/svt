require 'rails_helper'

module Warehouse
  module Orders
    RSpec.describe Edit, type: :model do
      let(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
      let!(:order) { create(:order, workplace: workplace) }
      subject { Edit.new(order.warehouse_order_id) }

      before { subject.run }

      its(:run) { is_expected.to be_truthy }

      it 'fills the @data with %i[order divisions eq_types order] keys' do
        expect(subject.data).to include(:order, :divisions, :eq_types)
      end

      it 'adds item_to_orders_attributes to order' do
        expect(subject.data[:order]).to include('operations_attributes')
      end

      it 'loads all operations attributes' do
        expect(subject.data[:order]['operations_attributes'].count).to eq order.operations.count
      end

      it 'replaces primary_key with id param' do
        expect(subject.data[:order]['operations_attributes'].first['id']).to eq order.operations.first.warehouse_operation_id
      end

      it 'adds invent_item_id to each operation' do
        expect(subject.data[:order]['operations_attributes'].first['invent_item_id']).to eq order.operations.first.item.inv_item.item_id
      end

      it 'adds get_item_model key' do
        expect(subject.data[:order]['operations_attributes'].first['inv_item']['get_item_model']).to eq order.operations.first.item.item_model
      end

      it 'adds consumer key' do
        expect(subject.data[:order]['consumer']).to eq subject.data[:order]['consumer_fio']
      end
    end
  end
end
