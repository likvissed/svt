require 'feature_helper'

module Warehouse
  module Supplies
    RSpec.describe Index, type: :model do
      let!(:supplies) { create_list(:supply, 30) }
      let(:params) { { start: 0, length: 25 } }
      subject { Index.new(params) }
      before { subject.run }

      it 'loads supplies specified into length param' do
        expect(subject.data[:data].count).to eq params[:length]
      end

      it 'adds total count of items to the each supply' do
        expect(subject.data[:data].first['total_count']).to eq supplies.first.operations.inject(0) { |sum, op| sum + op.shift  }
      end
    end
  end
end
