require 'feature_helper'

module Users
  RSpec.describe Destroy, type: :model do
    let!(:user) { create(:user) }
    subject { Destroy.new(user.id) }

    its(:run) { is_expected.to be_truthy }

    it 'destroys user' do
      expect { subject.run }.to change(User, :count).by(-1)
    end

    it 'broadcasts to users' do
      expect(subject).to receive(:broadcast_users)
      subject.run
    end

    context 'when user was not destroyed' do
      before { allow_any_instance_of(User).to receive(:destroy).and_return(false) }

      its(:run) { is_expected.to be_falsey }
    end
  end
end
