require 'feature_helper'

module Warehouse
  module Orders
    RSpec.describe Index, type: :model do
      let(:params) { { start: 0, length: 25 } }

      [:in, :out].each do |op_type|
        context "when :operation attribute has #{op_type} value" do
          let(:operation) { op_type }
          let!(:orders) { create_list(:order, 30, operation: operation) }
          subject { Index.new(params, operation: operation) }
          before { subject.run }

          it 'loads supplies specified into length param' do
            expect(subject.data[:data].count).to eq params[:length]
          end

          it 'loads order with :in operation' do
            expect(subject.data[:data].first['operation']).to eq operation.to_s
          end

          it 'adds %w[status_translated operation_translated operations_to_string] fields' do
            expect(subject.data[:data].first).to include('status_translated', 'operation_translated', 'operations_to_string')
          end
        end
      end
    end
  end
end
