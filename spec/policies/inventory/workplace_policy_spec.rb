require 'spec_helper'

module Inventory
  RSpec.describe WorkplacePolicy do
    subject { WorkplacePolicy }

    permissions '.scope' do
      let(:***REMOVED***_user) { create :***REMOVED***_user }
      let(:another_user) { create :user }
      let(:scope) do
        Workplace.left_outer_joins(:workplace_count)
      end
      subject(:policy_scope) { WorkplacePolicy::Scope.new(user, scope).resolve }

      context 'for users with ***REMOVED***_role' do
        let(:user) { ***REMOVED***_user }

        context 'when access allow' do
          let(:workplace_count) { create :active_workplace_count, users: [***REMOVED***_user] }
          let!(:workplace) do
            create :workplace_pk, :add_items, items: [:pc, :monitor], workplace_count: workplace_count
          end

          it 'shows workplaces' do
            expect(policy_scope).to eq [workplace]
          end
        end

        context 'when access deny' do
          let(:workplace_count) { create :active_workplace_count, users: [another_user] }
          let!(:workplace) do
            create :workplace_pk, :add_items, items: [:pc, :monitor], workplace_count: workplace_count
          end

          it 'not show workplaces' do
            expect(policy_scope).to eq []
          end
        end
      end

      context 'for another users' do
        let(:user) { another_user }
        let(:workplace_count) { create :active_workplace_count, users: [***REMOVED***_user] }
        let!(:workplace) do
          create :workplace_pk, :add_items, items: [:pc, :monitor], workplace_count: workplace_count
        end

        it 'shows all workplaces' do
          expect(policy_scope).to eq [workplace]
        end
      end
    end

    permissions :create? do
      let(:***REMOVED***_user) { create :***REMOVED***_user }
      let(:room) { create :iss_room }
      let(:workplace) { create_workplace_attributes }

      context 'with valid user' do
        context 'in allowed time' do
          let(:workplace_count) { create :active_workplace_count, users: [***REMOVED***_user] }

          it 'grants access to the workplace for current workplace_count' do
            expect(subject).to permit(***REMOVED***_user, Workplace.new(workplace))
          end
        end

        context 'out of allowed time' do
          let(:workplace_count) { create :inactive_workplace_count, users: [***REMOVED***_user] }

          it 'denies access to the workplace for current workplace_count' do
            expect(subject).not_to permit(***REMOVED***_user, Workplace.new(workplace))
          end
        end
      end

      context 'with invalid user' do
        let(:another_user) { create :user }

        context 'in allowed time' do
          let(:workplace_count) { create :active_workplace_count, users: [another_user] }

          it 'denies access to the workplace for current workplace_count' do
            expect(subject).not_to permit(***REMOVED***_user, Workplace.new(workplace))
          end
        end

        context 'out of allowed time' do
          let(:workplace_count) { create :inactive_workplace_count, users: [another_user] }

          it 'denies access to the workplace for current workplace_count' do
            expect(subject).not_to permit(***REMOVED***_user, Workplace.new(workplace))
          end
        end
      end
    end
  end
end