require 'spec_helper'

module Inventory
  RSpec.describe WorkplacePolicy do
    let(:user) { create :user }
    subject { WorkplacePolicy }

    permissions :load_workplace? do
      context 'with valid user' do
        let!(:workplace_count) { create :active_workplace_count, users: [user] }
        let!(:workplace) { create :workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count }

        it do
          is_expected.to permit(
            user,
            Workplace
              .left_outer_joins(:workplace_count)
              .where("invent_workplace_count.division = #{workplace_count.division}")
              .first
          )
        end
      end

      context 'with invalid user' do
        let(:workplace_count) { create :active_workplace_count }
        let(:workplace) { create :workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count }

        it do
          is_expected.not_to permit(
            create :***REMOVED***_user,
            Workplace
              .left_outer_joins(:workplace_count)
              .where("invent_workplace_count.division = #{workplace_count.division}")
              .first
          )
        end
      end
    end
  end
end