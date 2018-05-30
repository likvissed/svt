require 'feature_helper'

module Invent
  module Workplaces
    RSpec.describe Destroy, type: :model do
      let!(:user) { create(:user) }
      let!(:workplace) do
        wp = build(:workplace_pk)
        wp.save(validate: false)
        wp
      end
      subject { Destroy.new(user, workplace.workplace_id) }
      before do
        allow(Workplace).to receive(:find).and_return(workplace)
      end

      its(:run) { is_expected.to be_truthy }

      it 'runes :destroy method' do
        expect(workplace).to receive(:destroy)
        subject.run
      end

      it 'broadcasts to workplaces' do
        expect(subject).to receive(:broadcast_workplaces)
        subject.run
      end
    end
  end
end