require 'feature_helper'

module Invent
  module Items
    RSpec.describe PcConfigFromAudit, type: :model do
      let(:host_iss) { build(:host_iss) }
      subject { PcConfigFromAudit.new(host_iss[:id]) }

      it { is_expected.to validate_presence_of(:inv_num) }
      it { is_expected.not_to allow_value('').for(:inv_num) }

      context 'with valid inventory number' do
        context 'when Audit correctly works on the specified PC' do
          before { allow(Audit).to receive(:get_data).and_return(build(:audit)) }

          it 'returns a hash with %i[cpu ram hdd mb video last_connection] keys' do
            subject.run
            expect(subject.data).to include(:cpu, :ram, :hdd, :mb, :video, :last_connection)
          end

          its(:run) { is_expected.to be_truthy }
        end

        context 'when Audit does not work correctly (or not installed) on the specified PC' do
          before { allow(Audit).to receive(:get_data).and_return(nil) }

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

        context "when Audit did not update data more than #{Audit::MAX_RELENAVCE_TIME} days" do
          before { allow(Audit).to receive(:get_data).and_return(build(:audit, last_connection: [30.days.ago.to_s])) }

          it 'sets the :not_relevant error into the :base key' do
            subject.run
            expect(subject.errors.details[:base]).to include(error: :not_relevant)
          end

          its(:run) { is_expected.to be_falsey }
        end
      end

      context 'with invalid inventory number' do
        subject { PcConfigFromAudit.new(111_111) }

        it 'sets the :not_found error into :host key' do
          subject.run
          expect(subject.errors.details[:host]).to include(error: :not_found)
        end

        it 'does not run load_data method' do
          expect(subject).not_to receive(:load_data)
          subject.run
        end

        its(:run) { is_expected.to be_falsey }
      end
    end
  end
end
