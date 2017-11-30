require 'spec_helper'

module Invent
  module LkInvents
    RSpec.describe SvtAccess, type: :model do
      context 'with access' do
        let(:user) { create(:user) }
        let!(:workplace_count) { create(:active_workplace_count, users: [user]) }
        let(:expected_obj) do
          {
            workplace_count_id: workplace_count.workplace_count_id,
            division: workplace_count.division
          }
        end
        subject { SvtAccess.new(user.tn) }
        before { subject.run }

        it 'includes { access: true } into result object' do
          expect(subject.data).to include(access: true)
        end

        it 'includes array of divisions into result object' do
          expect(subject.data).to include(list: [expected_obj])
        end

        its(:run) { is_expected.to be_truthy }
      end

      context 'without access' do
        subject { SvtAccess.new('123456') }
        before { subject.run }

        it 'returns { access: false } object' do
          expect(subject.data).to include(access: false)
        end

        its(:run) { is_expected.to be_truthy }
      end
    end
  end
end
