require 'feature_helper'

module Warehouse
  module Orders
    RSpec.describe NewOrder, type: :model do
      skip_users_reference

      let!(:user) { create(:user) }
      let(:workplace_count) { create(:active_workplace_count, users: [user]) }
      subject { NewOrder.new(user, :in) }
      before { subject.run }

      context 'when order has :out type' do
        subject { NewOrder.new(user, 'out') }

        it 'does not fill the @data with :eq_types key' do
          expect(subject.data).not_to include(:eq_types)
        end

        it 'sets -1 to the shift attribute' do
          expect(subject.data[:operation].shift).to eq(-1)
        end
      end

      context 'when order has :in type' do
        subject { NewOrder.new(user, 'in') }

        it 'fills the @data with :eq_types key' do
          expect(subject.data).to include(:order, :eq_types, :divisions, :operation)
        end

        it 'loads all divisions to the :divisions key' do
          expect(subject.data[:divisions].length).to eq Invent::WorkplaceCount.count
        end

        it 'loads all types of equipment' do
          expect(subject.data[:eq_types].count).to eq Invent::Type.count
        end

        it 'sets 1 to the shift attribute' do
          expect(subject.data[:operation].shift).to eq 1
        end
      end

      it 'fills the @data with %w[order divisioins operation] keys' do
        expect(subject.data).to include(:order, :divisions, :operation)
      end

      it 'creates instance of Order' do
        expect(subject.data[:order]).to be_instance_of(Order)
      end

      Order.operations.each_key do |operation|
        context "when operation is #{operation}" do
          subject { NewOrder.new(user, operation) }

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
    end
  end
end
