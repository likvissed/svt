require 'spec_helper'

module Inventory
  RSpec.describe WorkplacePolicy do
    let(:***REMOVED***_user) { create :***REMOVED***_user }
    subject { WorkplacePolicy }

    permissions '.scope' do
      let(:another_user) { create :user }
      let(:scope) { Workplace.left_outer_joins(:workplace_count) }
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
      let(:room) { create :iss_room }
      let(:workplace) { create_workplace_attributes }

      context 'with valid user' do
        context 'when in allowed time' do
          let(:workplace_count) { create :active_workplace_count, users: [***REMOVED***_user] }

          it 'grants access to the workplace' do
            expect(subject).to permit(***REMOVED***_user, Workplace.new(workplace))
          end
        end

        context 'when out of allowed time' do
          let(:workplace_count) { create :inactive_workplace_count, users: [***REMOVED***_user] }

          it 'denies access to the workplace' do
            expect(subject).not_to permit(***REMOVED***_user, Workplace.new(workplace))
          end
        end
      end

      context 'with invalid user' do
        let(:another_user) { create :user }

        context 'when in allowed time' do
          let(:workplace_count) { create :active_workplace_count, users: [another_user] }

          it 'denies access to the workplace' do
            expect(subject).not_to permit(***REMOVED***_user, Workplace.new(workplace))
          end
        end

        context 'when out of allowed time' do
          let(:workplace_count) { create :inactive_workplace_count, users: [another_user] }

          it 'denies access to the workplace' do
            expect(subject).not_to permit(***REMOVED***_user, Workplace.new(workplace))
          end
        end
      end
    end

    permissions :edit? do
      let(:workplace_count) { create :active_workplace_count, users: [***REMOVED***_user] }
      let(:workplace) { create :workplace_mob, :add_items, items: %i[tablet], workplace_count: workplace_count }

      include_examples 'workplace policy with :***REMOVED***_user role'

      context 'with another role' do
        let(:admin_user) { create :user }

        it 'allows access to the workplace' do
          expect(subject).to permit(admin_user, Workplace.find(workplace.workplace_id))
        end

        context 'when out of allowed time' do
          let(:workplace_count) { create :inactive_workplace_count, users: [***REMOVED***_user] }

          it 'allows access to the workplace' do
            expect(subject).to permit(admin_user, Workplace.find(workplace.workplace_id))
          end
        end

        context 'when workplace status is confirmed' do
          let(:workplace) do
            create :workplace_mob, :add_items, items: %i[tablet], workplace_count: workplace_count, status: 'confirmed'
          end

          it 'allows access to the workplace' do
            expect(subject).to permit(admin_user, Workplace.find(workplace.workplace_id))
          end
        end
      end
    end

    permissions :update? do
      let(:workplace_count) { create :active_workplace_count, users: [***REMOVED***_user] }
      let(:room) { create :iss_room }
      let(:workplace) { create :workplace_mob, :add_items, items: %i[tablet], workplace_count: workplace_count }

      include_examples 'workplace policy with :***REMOVED***_user role'

      context 'when not :***REMOVED***_user role, but there is an opportunity to manage workplaces' do
        let(:admin_user) { create :user }
        let(:workplace_count) { create :active_workplace_count, users: [admin_user] }

        it 'allows access to the workplace' do
          expect(subject).to permit(admin_user, Workplace.find(workplace.workplace_id))
        end
      end

      context 'when another users (administrators, etc)' do
        let(:admin_user) { create :user }

        context 'when in allowed time' do
          it 'denies access to the workplace' do
            expect(subject).not_to permit(admin_user, Workplace.find(workplace.workplace_id))
          end
        end

        context 'when out of allowed time' do
          let(:workplace_count) { create :inactive_workplace_count, users: [***REMOVED***_user] }

          it 'allows access to the workplace' do
            expect(subject).to permit(admin_user, Workplace.find(workplace.workplace_id))
          end
        end
      end
    end
  end
end