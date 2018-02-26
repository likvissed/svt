require 'feature_helper'

module Warehouse
  module Orders
    RSpec.describe Edit, type: :model do
      let(:order) { create(:order, :default_workplace) }
      subject { Edit.new(order.id) }

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

      it 'loads inv_item_ids array for each operations attributes' do
        expect(subject.data[:order]['operations_attributes'].first['inv_item_ids']).to eq order.inv_item_to_operations.pluck(:invent_item_id)
      end

      it 'replaces primary_key with id param' do
        expect(subject.data[:order]['operations_attributes'].first['id']).to eq order.operations.first.id
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
