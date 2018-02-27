require 'feature_helper'

module Invent
  module LkInvents
    RSpec.describe DestroyWorkplace, type: :model do
      let(:user) { create(:user) }
      let(:workplace_count) { create(:active_workplace_count, users: [user]) }
      let!(:workplace) do
        create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count)
      end
      let(:prop_val_count) { workplace.items.inject(0) { |sum, item| sum + item.property_values.count } }
      subject { DestroyWorkplace.new(user, workplace.workplace_id) }

      it 'delete workplace' do
        expect { subject.run }.to change(Workplace, :count).by(-1)
      end

      it 'delete all items' do
        expect { subject.run }.to change(workplace.items, :count).by(-workplace.items.count)
      end

      it 'delete all property_values' do
        expect { subject.run }.to change(PropertyValue, :count). by(-prop_val_count)
      end

      its(:run) { is_expected.to be_truthy }
    end
  end
end
