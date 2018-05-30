require 'spec_helper'

module Invent
  RSpec.describe WorkplaceCountPolicy do
    let(:manager) { create(:***REMOVED***_user) }
    let(:worker) { create(:shatunova_user) }
    let(:read_only) { create(:tyulyakova_user) }
    let(:***REMOVED***_user) { create(:***REMOVED***_user) }
    subject { WorkplaceCountPolicy }

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

      ['manager', 'worker', 'read_only'].each do |user|
        context "with #{user} role" do
          it 'grants access to the workplace_count' do
            expect(subject).to permit(send(user), WorkplaceCount.find(workplace_count.workplace_count_id))
          end
        end
      end
    end
  end
end
