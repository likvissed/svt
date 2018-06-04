require 'spec_helper'

RSpec.describe UserPolicy do
  let(:manager) { create(:***REMOVED***_user) }
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
