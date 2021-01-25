require 'feature_helper'

describe 'Audit' do
  subject { Audit }

  describe '#configuration_data' do
    let(:audit) { build(:audit) }

    context 'when mac-address is valid' do
      let(:mac_name) { build(:host_iss)[:mac] }
      before { allow(subject).to receive(:configuration_data).and_return([audit]) }

      it 'returns a hash with params' do
        expect(subject.configuration_data(mac_name).first).to eq audit
      end
    end

    context 'when mac-address is invalid' do
      let(:mac_name) { '1 0 0' }
      before { allow(subject).to receive(:configuration_data).and_return([]) }

      it 'returns a hash with params' do
        expect(subject.configuration_data(mac_name)).to eq []
      end
    end
  end
end
