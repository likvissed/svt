require 'feature_helper'

module Warehouse
  module Items
    RSpec.describe Index, type: :model do
      let(:params) { { start: 0, length: 25 } }
      let!(:items) { create_list(:used_item, 30) }
      subject { Index.new(params) }

      it 'loads items specified into length param' do
        subject.run
        expect(subject.data[:data].count).to eq params[:length]
      end

      it 'adds :translated_used field' do
        subject.run
        expect(subject.data[:data].first).to include('translated_used')
      end

      let(:operation) { build(:order_operation, item: items.first, shift: -1) }
      let!(:order) { create(:order, operation: :out, operations: [operation]) }
      it 'loads all :processing orders with :out operation' do
        subject.run
        expect(subject.data[:orders].count).to eq 1
      end

      it 'adds :main_info field to each order' do
        subject.run
        expect(subject.data[:orders].first).to include(:main_info)
      end
    end
  end
end
