module Invent
  shared_examples 'user phone is changing' do
    let(:emp_user) { build(:emp_***REMOVED***) }
    let(:user) { User.find_by(tn: new_user.tn) }

    context 'when the phone is manually removed' do
      before { workplace_count[:users_attributes].first[:phone] = nil }

      it 'сhange the phone in User from UsersReference' do
        subject.run

        expect(user.phone).to eq emp_user['phoneText']
      end
    end

    context 'when the phone is entered manually' do
      let(:new_phone) { '11-22' }
      before { workplace_count[:users_attributes].first[:phone] = new_phone }

      it 'сhange the phone in User' do
        subject.run

        expect(user.phone).to eq new_phone
      end
    end
  end
end
