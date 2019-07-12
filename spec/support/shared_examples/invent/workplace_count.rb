module Invent
  shared_examples 'user phone is changing' do
    let(:user_iss) { UserIss.find_by(tn: new_user.tn) }
    let(:user) { User.find_by(tn: new_user.tn) }

    context 'when the phone is manually removed' do
      before { workplace_count[:users_attributes].first[:phone] = nil }

      it 'сhange the phone in User from UserIss' do
        subject.run

        expect(user.phone).to eq user_iss.tel
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
