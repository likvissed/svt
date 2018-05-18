require 'spec_helper'

module Warehouse
  RSpec.describe ItemPolicy do
    let(:manager) { create(:***REMOVED***_user) }
    subject { ItemPolicy }

    permissions :destroy? do
      context 'with :manager role' do
        let!(:item) { create(:used_item) }

        it 'grants access to the item' do
          expect(subject).to permit(manager, Item.first)
        end
      end
    end
  end
end
