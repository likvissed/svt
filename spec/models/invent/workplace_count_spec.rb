require 'feature_helper'

module Invent
  RSpec.describe WorkplaceCount, type: :model do
    it { is_expected.to have_many(:workplaces) }
    it { is_expected.to have_many(:workplace_responsibles).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:workplace_responsibles) }
    it { is_expected.to validate_presence_of(:division) }
    it { is_expected.to validate_presence_of(:time_start) }
    it { is_expected.to validate_presence_of(:time_end) }
    it { is_expected.to accept_nested_attributes_for(:users) }
    it { is_expected.to validate_numericality_of(:division).only_integer }
    skip_users_reference

    context 'when users is blank' do
      subject { build(:active_workplace_count) }
      before { allow(subject).to receive(:users).and_return(nil) }

      it 'workplace_count is invalid' do
        expect(subject.valid?).to be_falsey
      end

      it 'adds :add_at_least_one_responsible error' do
        subject.valid?
        expect(subject.errors.details[:base]).to include(error: :add_at_least_one_responsible)
      end
    end

    context 'when users is present' do
      let(:user) { create(:user) }
      subject { build(:active_workplace_count, users: [user]) }

      it 'workplace_count is vaild' do
        expect(subject.valid?).to be_truthy
      end
    end
  end
end
