require 'feature_helper'

module Users
  RSpec.describe Update, type: :model do
    let!(:user) { create(:***REMOVED***_user) }

    let(:user_params) do
      new_user = user.as_json
      new_user['tn'] = 101_101
      new_user
    end
    subject { Update.new(user.id, user_params) }

    its(:run) { is_expected.to be_truthy }

    it 'updates user data' do
      subject.run
      expect(user.reload.tn).to eq 101_101
    end

    it 'broadcasts to users' do
      expect(subject).to receive(:broadcast_users)
      subject.run
    end

    it 'sets user data' do
      expect_any_instance_of(User).to receive(:fill_data)
      subject.run
    end

    context 'when model was not saved' do
      before { allow_any_instance_of(User).to receive(:save).and_return(false) }

      its(:run) { is_expected.to be_falsey }

      it 'adds :object and :full_message keys to the error object' do
        subject.run
        expect(subject.error).to include(:object, :full_message)
      end
    end
  end
end
