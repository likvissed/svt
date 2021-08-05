require 'feature_helper'

module Users
  RSpec.describe Edit, type: :model do
    skip_users_reference

    let!(:user) { create(:user) }
    subject { Edit.new(user.id) }

    its(:run) { is_expected.to be_truthy }

    it 'adds :user and :roles keys to the data variable' do
      subject.run
      expect(subject.data).to include(:user, :roles)
    end
  end
end
