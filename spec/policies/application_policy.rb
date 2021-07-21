require 'spec_helper'

RSpec.describe ApplicationPolicy do
  let(:***REMOVED***_user) { create(:***REMOVED***_user) }
  let(:admin_user) { create(:user) }
  before { allow_any_instance_of(User).to receive(:presence_user_in_users_reference) }
  subject { ApplicationPolicy }

  permissions :authorization? do
    it 'grants access to any controller with :admin role' do
      expect(subject).to permit(admin_user)
    end

    it 'denies access to any controller except :***REMOVED***_invents to user with :***REMOVED***_user role' do
      expect(subject).not_to permit(***REMOVED***_user)
    end
  end
end
