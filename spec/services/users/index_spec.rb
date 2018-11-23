require 'feature_helper'

module Users
  RSpec.describe Index, type: :model do
    let!(:t_user) { create(:user) }
    let!(:b_user) { create(:***REMOVED***_user, sign_in_count: 1) }
    let(:data_keys) { %i[recordsTotal recordsFiltered data] }
    let(:params) { { start: 0, length: 25 } }
    subject { Index.new(params) }

    its(:run) { is_expected.to be_truthy }

    it 'fills the @data hash with %i[totalRecords data] keys' do
      subject.run
      expect(subject.data.keys).to include(*data_keys)
    end

    it 'adds %w[role online?] fields to each item' do
      subject.run
      expect(subject.data[:data].first).to include('role', 'online?')
    end

    context 'when user already logged in' do
      before do
        allow_any_instance_of(User).to receive(:current_sign_in_at).and_return(Time.zone.now)
        allow_any_instance_of(User).to receive(:last_sign_in_at).and_return(Time.zone.now)
      end

      it 'adds %w[current_sign_in_data last_sign_in_data] fields to each item' do
        subject.run
        expect(subject.data[:data].first).to include('current_sign_in_data', 'last_sign_in_data')
      end
    end

    context 'with filters' do
      let(:filter) { {} }
      subject do
        params[:filters] = filter
        Index.new(params)
      end
      before { subject.run }

      context 'and with :fullname filter' do
        let(:fullname) { '***REMOVED***' }
        let(:filter) { { fullname: fullname }.to_json }

        it 'returns filtered data' do
          subject.data[:data].each do |user|
            expect(user['fullname']).to eq b_user.fullname
          end
        end
      end

      context 'and with :role_id filter' do
        let(:role_id) { Role.first.id }
        let(:filter) { { role_id: role_id }.to_json }

        it 'returns filtered data' do
          subject.data[:data].each do |user|
            expect(user['role_id']).to eq role_id
          end
        end
      end

      context 'and with :online filter' do
        let(:online) { true }
        let(:filter) { { online: online }.to_json }

        it 'returns filtered data' do
          subject.data[:data].each do |user|
            expect(user['online?']).to be_truthy
          end
        end
      end
    end
  end
end
