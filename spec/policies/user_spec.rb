require 'spec_helper'

RSpec.describe UserPolicy do
  let(:manager) { create(:***REMOVED***_user) }
  before { allow_any_instance_of(User).to receive(:presence_user_in_users_reference) }
  subject { UserPolicy }

  permissions :ctrl_access? do
    context 'with :manager role' do
      let!(:user) { create(:user) }

      it 'grants access to the model' do
        expect(subject).to permit(manager, User.first)
      end
    end
  end
end
