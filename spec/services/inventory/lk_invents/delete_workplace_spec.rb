require 'spec_helper'

module Inventory
  module LkInvents
    RSpec.describe DeleteWorkplace, type: :model do
      let!(:workplace_count) { create(:active_workplace_count, users: [build(:user)]) }
      let!(:workplace) do
        create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count)
      end
      let(:prop_val_count) do
        count = 0
        workplace.inv_items.each { |item| count += item.inv_property_values.count }
        count
      end
      subject { DeleteWorkplace.new(workplace.workplace_id) }

      it 'delete workplace' do
        expect { subject.run }.to change(Workplace, :count).by(-1)
      end

      it 'delete all inv_items' do
        expect { subject.run }.to change(workplace.inv_items, :count).by(-workplace.inv_items.count)
      end

      it 'delete all inv_property_values' do
        expect { subject.run }.to change(InvPropertyValue, :count). by(-prop_val_count)
      end

      its(:run) { is_expected.to be_truthy }
    end
  end
end