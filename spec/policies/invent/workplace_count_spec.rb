require 'spec_helper'

module Invent
  RSpec.describe WorkplaceCountPolicy do
    let(:manager) { create(:***REMOVED***_user) }
    let(:worker) { create(:shatunova_user) }
    let(:read_only) { create(:tyulyakova_user) }
    let(:***REMOVED***_user) { create(:***REMOVED***_user) }
    subject { WorkplaceCountPolicy }

    permissions '.scope' do
      let(:scope) { WorkplaceCount }
      subject(:policy_scope) { WorkplaceCountPolicy::Scope.new(user, scope).resolve }

      context 'for users with ***REMOVED***_role' do
        let(:user) { ***REMOVED***_user }
        let!(:wp_c) { create(:active_workplace_count, users: [user]) }

        # it 'shows only user workplace_counts' do
        #   expect(policy_scope).to eq [wp_c]
        # end
      end

      context 'for another users' do
        let(:user) { manager }

        it 'shows all workplace_counts' do
          expect(policy_scope.count).to eq WorkplaceCount.count
        end
      end
    end

    permissions :ctrl_access? do
      let(:model) { create(:active_workplace_count, users: [***REMOVED***_user]) }

      include_examples 'policy not for ***REMOVED***_user'
    end

    permissions :generate_pdf? do
      let!(:workplace_count) { create(:active_workplace_count, users: [***REMOVED***_user]) }

      context 'with :***REMOVED***_user role' do
        context 'and with valid user' do
          it 'grants access to the workplace_count' do
            expect(subject).to permit(***REMOVED***_user, WorkplaceCount.find(workplace_count.workplace_count_id))
          end
        end

        context 'and with invalid user' do
          let(:another_user) { create(:user, role: ***REMOVED***_user.role) }

          it 'denies access to the workplace_count' do
            expect(subject).not_to permit(another_user, WorkplaceCount.find(workplace_count.workplace_count_id))
          end
        end
      end

      %w[manager worker read_only].each do |user|
        context "with #{user} role" do
          it 'grants access to the workplace_count' do
            expect(subject).to permit(send(user), WorkplaceCount.find(workplace_count.workplace_count_id))
          end
        end
      end
    end
  end
end
