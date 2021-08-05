require 'spec_helper'

module Invent
  RSpec.describe WorkplacePolicy do
    let(:manager) { create(:***REMOVED***_user) }
    let(:worker) { create(:shatunova_user) }
    let(:read_only) { create(:tyulyakova_user) }
    let(:***REMOVED***_user) { create(:***REMOVED***_user) }
    before do
      allow_any_instance_of(User).to receive(:presence_user_in_users_reference)
      allow_any_instance_of(UserIssByIdTnValidator).to receive(:validate_each)
    end

    subject { WorkplacePolicy }

    permissions '.scope' do
      let(:another_user) { create(:user) }
      let(:scope) { Workplace.left_outer_joins(:workplace_count) }
      subject(:policy_scope) { WorkplacePolicy::Scope.new(user, scope).resolve }

      context 'for users with ***REMOVED***_role' do
        let(:user) { ***REMOVED***_user }

        context 'and when access allow' do
          let(:workplace_count) { create(:active_workplace_count, users: [***REMOVED***_user]) }
          let!(:workplace) do
            create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count)
          end

          it 'shows workplaces' do
            expect(policy_scope).to eq [workplace]
          end
        end

        context 'and when access deny' do
          let(:workplace_count) { create(:active_workplace_count, users: [another_user]) }
          let!(:workplace) do
            create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count)
          end

          it 'not show workplaces' do
            expect(policy_scope).to eq []
          end
        end
      end

      context 'for another users' do
        let(:user) { another_user }
        let(:workplace_count) { create(:active_workplace_count, users: [***REMOVED***_user]) }
        let!(:workplace) do
          create(:workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count)
        end

        it 'shows all workplaces' do
          expect(policy_scope).to eq [workplace]
        end
      end
    end

    permissions :ctrl_access? do
      context 'with ***REMOVED***_user role' do
        context 'and when user has workplace_count' do
          let!(:wp_c) { create(:active_workplace_count, users: [***REMOVED***_user]) }

          it 'grants access' do
            expect(subject).to permit(***REMOVED***_user, [:invent, :workplace])
          end
        end

        context 'and when user does not have workplace_count' do
          let!(:wp_c) { create(:active_workplace_count, users: [manager]) }

          it 'denies access' do
            expect(subject).not_to permit(***REMOVED***_user, [:invent, :workplace])
          end
        end
      end

      %w[manager worker read_only].each do |role|
        context "with #{role} role" do
          it 'grants access' do
            expect(subject).to permit(send(role), [:invent, :workplace])
          end
        end
      end
    end

    permissions :new? do
      include_examples 'workplace policy with :***REMOVED***_user role for new workplace'
      include_examples 'workplace policy for another roles'

      # context 'with ***REMOVED***_user' do
      #   it 'grants access' do
      #     expect(subject).to permit(***REMOVED***_user, Workplace.new())
      #   end
      # end
    end

    permissions :create? do
      include_examples 'workplace policy with :***REMOVED***_user role for create workplace'
      include_examples 'workplace policy for another roles'
    end

    permissions :edit? do
      let(:workplace_count) { create(:active_workplace_count, users: [***REMOVED***_user]) }
      let(:workplace) { create(:workplace_mob, :add_items, items: %i[tablet], workplace_count: workplace_count) }

      include_examples 'workplace policy with :***REMOVED***_user role for existing workplace'

      ['manager', 'worker', 'read_only'].each do |user|
        context "with #{user} role" do
          it 'grants access to the workplace' do
            expect(subject).to permit(send(user), Workplace.find(workplace.workplace_id))
          end
        end
      end
    end

    permissions :update? do
      let(:workplace_count) { create(:active_workplace_count, users: [***REMOVED***_user]) }
      let(:workplace) { create(:workplace_mob, :add_items, items: %i[tablet], workplace_count: workplace_count) }

      include_examples 'workplace policy with :***REMOVED***_user role for existing workplace'
      include_examples 'workplace policy for another roles'

      context 'when workplace has disapproved status' do
        before { workplace.status = :disapproved }

        it 'sets :pending_verification status' do
          expect(subject).to permit(***REMOVED***_user, workplace)
          expect(workplace.status).to eq 'pending_verification'
        end
      end
    end

    # permissions :destroy? do
    #   let(:workplace_count) { create(:active_workplace_count, users: [***REMOVED***_user]) }
    #   let!(:workplace) { create(:workplace_mob, :add_items, items: %i[tablet], workplace_count: workplace_count) }

    #   context 'when :***REMOVED***_user role' do
    #     context 'and with valid user, in allowed time, when workplace status is not confirmed' do
    #       it 'grants access to the workplace' do
    #         expect(subject).to permit(***REMOVED***_user, Workplace.find(workplace.workplace_id))
    #       end
    #     end

    #     context 'and with invalid user' do
    #       let(:another_user) { create(:user, role: ***REMOVED***_user.role) }

    #       it 'denies access to the workplace' do
    #         expect(subject).not_to permit(another_user, Workplace.find(workplace.workplace_id))
    #       end
    #     end

    #     context 'and when out of allowed time' do
    #       let(:workplace_count) { create(:inactive_workplace_count, users: [***REMOVED***_user]) }

    #       it 'denies access to the workplace' do
    #         expect(subject).not_to permit(***REMOVED***_user, Workplace.find(workplace.workplace_id))
    #       end
    #     end

    #     context 'and when workplace status is confirmed' do
    #       let(:workplace) do
    #         create(:workplace_mob, :add_items, items: %i[tablet], workplace_count: workplace_count, status: 'confirmed')
    #       end

    #       it 'denies access to the workplace' do
    #         expect(subject).not_to permit(***REMOVED***_user, Workplace.find(workplace.workplace_id))
    #       end
    #     end
    #   end

    #   context 'with :manager role' do
    #     let(:user) { create(:***REMOVED***_user) }

    #     it 'grants access to the workplace' do
    #       expect(subject).to permit(user, Workplace.find(workplace.workplace_id))
    #     end
    #   end
    # end

    permissions :hard_destroy? do
      let!(:workplace) { create(:workplace_mob, :add_items, items: %i[tablet]) }

      context 'when :manager role' do
        let(:manager) { create(:***REMOVED***_user) }

        it 'grants access to the workplace' do
          expect(subject).to permit(manager, Workplace.find(workplace.workplace_id))
        end
      end
    end

    permissions :destroy? do
      let!(:workplace) { create(:workplace_mob, :add_items, items: %i[tablet]) }

      context 'when :manager role' do
        let(:manager) { create(:***REMOVED***_user) }

        it 'grants access to the workplace' do
          expect(subject).to permit(manager, Workplace.find(workplace.workplace_id))
        end
      end
    end
  end
end
