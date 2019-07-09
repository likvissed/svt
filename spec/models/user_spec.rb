require 'feature_helper'

RSpec.describe User, type: :model do
  it { is_expected.to have_many(:workplace_responsibles).class_name('Invent::WorkplaceResponsible').dependent(:destroy) }
  it { is_expected.to have_many(:workplace_counts).through(:workplace_responsibles).class_name('Invent::WorkplaceCount') }
  it { is_expected.to belong_to(:role) }
  it { is_expected.to belong_to(:user_iss).with_foreign_key('id_tn') }
  # it { is_expected.to validate_presence_of(:tn) }
  it { is_expected.to validate_presence_of(:role) }
  it { is_expected.to validate_numericality_of(:tn).only_integer }

  describe '#fill_data' do
    context 'when :tn is valid' do
      let(:tn) { ***REMOVED*** }
      let(:user_iss) { UserIss.find_by(tn: tn) }
      before { subject.tn = tn }

      it 'fills subject with data finded into UserIss table' do
        subject.fill_data
        expect(subject.id_tn).to eq user_iss.id_tn
        expect(subject.fullname).to eq user_iss.fio
        expect(subject.phone).to eq user_iss.tel
      end
    end

    context 'when :tn is invalid' do
      let(:tn) { ***REMOVED***_123_123 }
      let(:user_iss) { UserIss.find_by(tn: tn) }
      before { subject.tn = tn }

      it 'does not fill subject with any data' do
        expect(subject.id_tn).to be_nil
        expect(subject.fullname).to be_nil
        expect(subject.phone).to be_empty
      end
    end
  end

  describe '#user_not_found' do
    let(:tn) { 123_123_123_123 }

    context 'when array of errors is present' do
      before { subject.tn = tn }

      it 'does not call method :user_not_found' do
        expect(subject).not_to receive(:user_not_found)

        subject.valid?
      end
    end

    context 'when user not found in UserIss' do
      subject { build(:***REMOVED***_user, tn: tn) }

      it 'calls error :user_not_found' do
        subject.valid?

        expect(subject.errors.details[:tn]).to include(error: :user_not_found, tn: tn)
      end
    end
  end
end
