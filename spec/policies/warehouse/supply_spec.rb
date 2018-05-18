require 'spec_helper'

module Warehouse
  RSpec.describe SupplyPolicy do
    let(:manager) { create(:***REMOVED***_user) }
    subject { SupplyPolicy }

    permissions :new? do
      context 'with :manager role' do
        it 'grants access to the supply' do
          expect(subject).to permit(manager, Order.new)
        end
      end
    end

    permissions :create? do
      context 'with :manager role' do
        it 'grants access to the supply' do
          expect(subject).to permit(manager, Supply.new)
        end
      end
    end

    permissions :edit? do
      context 'with :manager role' do
        let!(:supply) { create(:supply) }

        it 'grants access to the supply' do
          expect(subject).to permit(manager, Supply.find(supply.id))
        end
      end
    end

    permissions :update? do
      context 'with :manager role' do
        let!(:supply) { create(:supply) }

        it 'grants access to the supply' do
          expect(subject).to permit(manager, Supply.find(supply.id))
        end
      end
    end

    permissions :destroy? do
      context 'with :manager role' do
        let!(:supply) { create(:supply) }

        it 'grants access to the supply' do
          expect(subject).to permit(manager, Supply.find(supply.id))
        end
      end
    end
  end
end
