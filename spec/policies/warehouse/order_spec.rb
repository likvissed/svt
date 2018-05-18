require 'spec_helper'

module Warehouse
  RSpec.describe OrderPolicy do
    let(:manager) { create(:***REMOVED***_user) }
    subject { OrderPolicy }

    permissions :new? do
      context 'with :manager role' do
        it 'grants access to the order' do
          expect(subject).to permit(manager, Order.new)
        end
      end
    end

    permissions :create? do
      context 'with :manager role' do
        it 'grants access to the order' do
          expect(subject).to permit(manager, Order.new)
        end
      end
    end

    permissions :update? do
      context 'with :manager role' do
        let!(:order) { create(:order, operation: :in) }

        it 'grants access to the order' do
          expect(subject).to permit(manager, Order.find(order.id))
        end
      end
    end

    permissions :execute_in? do
      context 'with :manager role' do
        let!(:order) { create(:order, operation: :in) }

        it 'grants access to the order' do
          expect(subject).to permit(manager, Order.find(order.id))
        end
      end
    end

    permissions :execute_out? do
      context 'with :manager role' do
        let!(:order) { create(:order, operation: :out) }

        it 'grants access to the order' do
          expect(subject).to permit(manager, Order.find(order.id))
        end
      end
    end

    permissions :destroy? do
      context 'with :manager role' do
        let!(:order) { create(:order, operation: :out) }

        it 'grants access to the order' do
          expect(subject).to permit(manager, Order.find(order.id))
        end
      end
    end

    permissions :prepare_to_deliver? do
      context 'with :manager role' do
        let!(:order) { create(:order, operation: :out) }

        it 'grants access to the order' do
          expect(subject).to permit(manager, Order.find(order.id))
        end
      end
    end
  end
end
