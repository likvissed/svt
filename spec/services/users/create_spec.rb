require 'feature_helper'

module Users
  RSpec.describe Create, type: :model do
    let!(:role) { create(:admin_role) }
    let(:user_params) { attributes_for(:user, role_id: role.id) }
    subject { Create.new(user_params.as_json) }

    its(:run) { is_expected.to be_truthy }

    it 'creates user' do
      expect { subject.run }.to change(User, :count).by(1)
    end

    it 'sets user data' do
      expect_any_instance_of(User).to receive(:fill_data)
      subject.run
    end

    it 'broadcasts to users' do
      expect(subject).to receive(:broadcast_users)
      subject.run
    end
  end
end
