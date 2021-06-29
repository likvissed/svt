require 'feature_helper'

describe 'UsersReference' do
  subject { UsersReference }

  describe '#new_token_hr' do
    it 'return of successful status' do
      allow(subject).to receive(:new_token_hr).and_return('OK')

      expect(subject.new_token_hr).to eq 'OK'
    end

    it 'overwrites the token in the cache' do
      allow(subject).to receive(:new_token_hr).and_return(Rails.cache.write('token_hr', '111'))

      expect do
        allow(subject).to receive(:new_token_hr).and_return(Rails.cache.write('token_hr', '222'))
      end.to change { Rails.cache.read('token_hr') }
    end
  end

  describe '#user_where' do
    context 'when params_search is valid' do
      let(:employee) { build(:emp_***REMOVED***) }
      let(:params_search) { "personnelNo==#{employee['personnelNo']}" }

      it 'return user data' do
        allow(subject).to receive(:user_where).with(params_search).and_return([employee])

        expect(subject.user_where(params_search)).to eq [employee]
      end
    end

    context 'when params_search is not valid' do
      let(:params_search) { nil }

      it 'return data is nil' do
        allow(subject).to receive(:user_where).with(params_search).and_return(nil)

        expect(subject.user_where(params_search)).to be_nil
      end
    end
  end

  describe '#info_users' do
    context 'when response code is 200' do
      let(:params) { 'personnelNo==0' }

      it 'get a new token' do
        Rails.cache.delete('token_hr')
        allow(subject).to receive(:new_token_hr).and_return(Rails.cache.write('token_hr', '111'))

        expect do
          allow(subject).to receive(:info_users).with(params)
          allow(subject).to receive(:new_token_hr).and_return(Rails.cache.write('token_hr', '222'))
        end.to change { Rails.cache.read('token_hr') }
      end

      it 'return is empty array' do
        allow(subject).to receive(:info_users).with(params).and_return([])

        expect(subject.info_users(params)).to eq []
      end

      context 'and when token is empty' do
        before { Rails.cache.write('token_hr', []) }

        it 'overwrites the token in the cache' do
          expect do
            allow(subject).to receive(:info_users).with(params)
            allow(subject).to receive(:new_token_hr).and_return(Rails.cache.write('token_hr', '123'))
          end.to change { Rails.cache.read('token_hr') }
        end
      end
    end

    context 'when response code is 500' do
      let(:params) { 'personnelNo==' }

      it 'return is empty array' do
        allow(subject).to receive(:info_users).with(params).and_return([])

        expect(subject.info_users(params)).to eq []
      end

      context 'and when token is present' do
        before { Rails.cache.write('token_hr', 123_123) }

        it 'delete and get a new token in cache' do
          expect do
            allow(subject).to receive(:info_users).with(params)
            allow(subject).to receive(:new_token_hr).and_return(Rails.cache.write('token_hr', '123'))
          end.to change { Rails.cache.read('token_hr') }
        end
      end
    end
  end
end
