require 'feature_helper'

RSpec.describe User, type: :model do
  it { is_expected.to have_many(:workplace_responsibles).class_name('Invent::WorkplaceResponsible').dependent(:destroy) }
  it { is_expected.to have_many(:workplace_counts).through(:workplace_responsibles).class_name('Invent::WorkplaceCount') }
  it { is_expected.to belong_to(:role) }
  # it { is_expected.to validate_presence_of(:tn) }
  it { is_expected.to validate_presence_of(:role) }
  it { is_expected.to validate_numericality_of(:tn).only_integer }

  describe '#fill_data' do
    let(:result_subject) do
      subj = subject
      subj.id_tn = employee.try(:[], 'id')
      subj.fullname = employee.try(:[], 'fullName')
      subj.phone = employee.try(:[], 'phoneText')
      subj
    end

    context 'when :tn is valid' do
      let(:tn) { ***REMOVED*** }
      let(:employee) { build(:emp_***REMOVED***) }
      before { subject.tn = tn }

      it 'fills subject with data finded into UserIss table' do
        allow(subject).to receive(:fill_data).and_return(result_subject)

        expect(subject.id_tn).to eq employee['id']
        expect(subject.fullname).to eq employee['fullName']
        expect(subject.phone).to eq employee['phoneText']
      end
    end

    context 'when :tn is invalid' do
      let(:tn) { ***REMOVED***_123_123 }
      let(:employee) { build(:emp_empty) }
      before { subject.tn = tn }

      it 'does not fill subject with any data' do
        expect(subject.id_tn).to be_nil
        expect(subject.fullname).to be_nil
        expect(subject.phone).to be_empty
      end
    end
  end

  describe '#presence_user_in_users_reference' do
    let(:tn) { 123_123_123_123 }

    context 'when array of errors is present' do
      before { subject.tn = tn }

      it 'does not call method :presence_user_in_users_reference' do
        expect(subject).not_to receive(:presence_user_in_users_reference)

        subject.valid?
      end
    end

    context 'when user not found in UserIss' do
      subject { build(:***REMOVED***_user, tn: tn) }
      let(:add_error_subject) do
        sub = subject
        sub.errors.details[:tn] = [{ error: :user_not_found, tn: tn }]
        sub
      end

      it 'calls error :user_not_found' do
        allow(subject).to receive(:presence_user_in_users_reference).and_return(add_error_subject)
        # subject.valid?

        expect(subject.errors.details[:tn]).to include(error: :user_not_found, tn: tn)
      end
    end
  end
end
