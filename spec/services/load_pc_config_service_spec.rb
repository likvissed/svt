require 'spec_helper'

RSpec.describe LoadPcConfigService, type: :model do
  # PC 'ravil'
  subject { LoadPcConfigService.new(764196) }

  it { is_expected.to validate_presence_of(:inv_num) }
  it { is_expected.not_to allow_value('').for(:inv_num) }

  context 'with valid inventory number' do
    it 'runs validator' do
      expect(subject).to receive(:run_validations)
      subject.run
    end

    %w[get_host_name load_data].each do |method|
      it "runs '#{method}' method" do
        expect(subject).to receive(method.to_sym)
        subject.run
      end
    end

    context 'when Audit correctly works on the specified PC' do
      # PC 'mikhail'
      subject { LoadPcConfigService.new(762341) }

      it 'returns a hash with %i[cpu ram hdd mb video last_connection] keys' do
        subject.run
        expect(subject.data).to include(:cpu, :ram, :hdd, :mb, :video, :last_connection)
      end

      its(:run) { is_expected.to be_truthy }
    end

    context 'when Audit does not work correctly (or not installed) on the specified PC' do
      it 'assigns the data nil' do
        subject.run
        expect(subject.data).to be_nil
      end

      it 'sets the :empty_data error into the :base key' do
        subject.run
        expect(subject.errors.details[:base]).to include(error: :empty_data)
      end

      its(:run) { is_expected.to be_falsey }
    end

    context "when Audit did not update data for more than #{Audit::MAX_RELENAVCE_TIME} days" do
      # PC '372637ed6a7a47e'
      subject { LoadPcConfigService.new(755834) }

      it 'sets the :empty_data error into the :base key' do
        subject.run
        expect(subject.errors.details[:base]).to include(error: :not_relevant)
      end

      its(:run) { is_expected.to be_falsey }
    end
  end

  context 'with invalid inventory number' do
    # PC 'unknown'
    subject { LoadPcConfigService.new(1) }

    it 'does not run load_data method' do
      expect(subject).not_to receive(:load_data)
      subject.run
    end

    its(:run) { is_expected.to be_falsey }
  end
end
