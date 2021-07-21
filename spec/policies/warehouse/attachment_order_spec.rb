require 'spec_helper'

module Warehouse
  RSpec.describe AttachmentOrderPolicy do
    let(:***REMOVED***_user) { create(:***REMOVED***_user) }
    let(:manager) { create(:***REMOVED***_user) }
    let(:worker) { create(:shatunova_user) }
    let(:read_only) { create(:tyulyakova_user) }
    before do
      allow_any_instance_of(User).to receive(:presence_user_in_users_reference)
      create(:used_item)
    end
    subject { AttachmentOrderPolicy }

    permissions :create? do
      context 'with ***REMOVED***_user role' do
        context 'and when user has workplace_count' do
          let!(:wp_c) { create(:active_workplace_count, users: [***REMOVED***_user]) }

          it 'grants access' do
            expect(subject).not_to permit(***REMOVED***_user, [:warehouse, :attachment_order])
          end
        end

        context 'and when user does not have workplace_count' do
          let!(:wp_c) { create(:active_workplace_count, users: [manager]) }

          it 'denies access' do
            expect(subject).not_to permit(***REMOVED***_user, [:warehouse, :attachment_order])
          end
        end
      end

      %w[manager worker].each do |role|
        context "with #{role} role" do
          it 'grants access' do
            expect(subject).to permit(send(role), [:warehouse, :attachment_order])
          end
        end
      end
    end
  end
end
