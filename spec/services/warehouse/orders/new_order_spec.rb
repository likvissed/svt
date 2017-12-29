require 'spec_helper'

module Warehouse
  module Orders
    RSpec.describe NewOrder, type: :model do
      let(:user) { create(:user) }
      let(:workplace_count) { create(:active_workplace_count, users: [user]) }
      subject { NewOrder.new(:in) }
      before { subject.run }

      it 'fills the @data with %w[order operation divisioins operation] keys' do
        expect(subject.data).to include(:order, :eq_types, :divisions, :operation)
      end

      it 'loads all divisions to the :divisions key' do
        expect(subject.data[:divisions].length).to eq Invent::WorkplaceCount.count
      end

      it 'creates instance of Order' do
        expect(subject.data[:order]).to be_instance_of(Order)
      end

      Order.operations.keys.each do |operation|
        context "when operation is #{operation}" do
          subject { NewOrder.new(operation) }

          it 'creates Order with specified status' do
            expect(subject.data[:order].operation).to eq operation
          end
        end
      end

      it 'create instance of :in operation' do
        expect(subject.data[:operation]).to be_instance_of(Operation)
      end

      it 'sets operationable_type to "Warehouse::Order"' do
        expect(subject.data[:operation].operationable_type).to eq 'Warehouse::Order'
      end

      it 'loads all types of equipment' do
        expect(subject.data[:eq_types].count).to eq Invent::Type.count - 1
      end
    end
  end
end
