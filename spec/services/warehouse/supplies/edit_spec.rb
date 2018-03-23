require 'feature_helper'

module Warehouse
  module Supplies
    RSpec.describe Edit, type: :model do
      let(:supply) { create(:supply) }
      subject { Edit.new(supply.id) }

      before { subject.run }

      its(:run) { is_expected.to be_truthy }

      it 'fills the @data with [supply operation eq_types] keys' do
        expect(subject.data).to include(:supply, :operation, :eq_types)
      end

      it 'adds item_to_orders_attributes to order' do
        expect(subject.data[:supply]).to include('operations_attributes')
      end

      it 'loads all operations attributes' do
        expect(subject.data[:supply]['operations_attributes'].size).to eq supply.operations.count
      end

      it 'loads item for each operation' do
        expect(subject.data[:supply]['operations_attributes'].first['item']).to include('id', 'warehouse_type', 'invent_model_id', 'invent_type_id', 'item_model', 'item_model')
      end
    end
  end
end
