require 'spec_helper'

module Invent
  RSpec.describe WorkplacePolicy do
    let(:***REMOVED***_user) { create :***REMOVED***_user }
    subject { WorkplacePolicy }

    permissions '.scope' do
      let(:another_user) { create :user }
      let(:scope) { Workplace.left_outer_joins(:workplace_count) }
      subject(:policy_scope) { WorkplacePolicy::Scope.new(user, scope).resolve }

      context 'for users with ***REMOVED***_role' do
        let(:user) { ***REMOVED***_user }

        context 'and when access allow' do
          let(:workplace_count) { create :active_workplace_count, users: [***REMOVED***_user] }
          let!(:workplace) do
            create :workplace_pk, :add_items, items: [:pc, :monitor], workplace_count: workplace_count
          end

          it 'shows workplaces' do
            expect(policy_scope).to eq [workplace]
          end
        end

        context 'and when access deny' do
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
      let(:workplace) { create_workplace_attributes(room: IssReferenceSite.first.iss_reference_buildings.first.iss_reference_rooms.first) }

      context 'with :***REMOVED***_user role' do
        context 'and when in allowed time' do
          let(:workplace_count) { create :active_workplace_count, users: [***REMOVED***_user] }

          it 'grants access to the workplace' do
            expect(subject).to permit(***REMOVED***_user, Workplace.new(workplace))
          end
        end

        context 'and when out of allowed time' do
          let(:workplace_count) { create :inactive_workplace_count, users: [***REMOVED***_user] }

          it 'denies access to the workplace' do
            expect(subject).not_to permit(***REMOVED***_user, Workplace.new(workplace))
          end
        end
      end

      context 'with :manager role' do
        let(:manager) { create :***REMOVED***_user }
        let(:workplace_count) { create :active_workplace_count, users: [***REMOVED***_user] }

        it 'grants access to the workplace' do
          expect(subject).to permit(manager, Workplace.new(workplace))
        end
      end
    end

    permissions :edit? do
      let(:workplace_count) { create :active_workplace_count, users: [***REMOVED***_user] }
      let(:workplace) { create :workplace_mob, :add_items, items: %i[tablet], workplace_count: workplace_count }

      include_examples 'workplace policy with :***REMOVED***_user role'

      context 'with :manager role' do
        let(:manager) { create :***REMOVED***_user }

        it 'grants access to the workplace' do
          expect(subject).to permit(manager, Workplace.find(workplace.workplace_id))
        end
      end
    end

    permissions :update? do
      let(:workplace_count) { create :active_workplace_count, users: [***REMOVED***_user] }
      let(:workplace) { create :workplace_mob, :add_items, items: %i[tablet], workplace_count: workplace_count }

      include_examples 'workplace policy with :***REMOVED***_user role'

      context 'with :manager role' do
        let(:user) { create :***REMOVED***_user }

        it 'grants access to the workplace' do
          expect(subject).to permit(user, Workplace.find(workplace.workplace_id))
        end
      end
    end

    permissions :destroy? do
      let(:workplace_count) { create :active_workplace_count, users: [***REMOVED***_user] }
      let!(:workplace) { create :workplace_mob, :add_items, items: %i[tablet], workplace_count: workplace_count }

      context 'when :***REMOVED***_user role' do
        context 'and with valid user, in allowed time, when workplace status is not confirmed' do
          it 'grants access to the workplace' do
            expect(subject).to permit(***REMOVED***_user, Workplace.find(workplace.workplace_id))
          end
        end

        context 'and with invalid user' do
          let(:another_user) { create :user, role: ***REMOVED***_user.role }

          it 'denies access to the workplace' do
            expect(subject).not_to permit(another_user, Workplace.find(workplace.workplace_id))
          end
        end

        context 'and when out of allowed time' do
          let(:workplace_count) { create :inactive_workplace_count, users: [***REMOVED***_user] }

          it 'denies access to the workplace' do
            expect(subject).not_to permit(***REMOVED***_user, Workplace.find(workplace.workplace_id))
          end
        end

        context 'and when workplace status is confirmed' do
          let(:workplace) do
            create :workplace_mob, :add_items, items: %i[tablet], workplace_count: workplace_count, status: 'confirmed'
          end

          it 'denies access to the workplace' do
            expect(subject).not_to permit(***REMOVED***_user, Workplace.find(workplace.workplace_id))
          end
        end
      end

      context 'with :manager role' do
        let(:user) { create :***REMOVED***_user }

        it 'grants access to the workplace' do
          expect(subject).to permit(user, Workplace.find(workplace.workplace_id))
        end
      end
    end
  end
end