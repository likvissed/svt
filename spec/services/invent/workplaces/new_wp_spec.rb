require 'feature_helper'

module Invent
  module Workplaces
    RSpec.describe NewWp, type: :model do
      let(:user) { create(:user) }
      let!(:workplace_count) { create(:active_workplace_count, users: [user]) }
      let(:properties) do
        prop = LkInvents::InitProperties.new(user)
        prop.run
        prop.data
      end
      subject { NewWp.new(user) }

      its(:run) { is_expected.to be_truthy }

      it 'fills the @data with %w[prop_data workplace] keys' do
        subject.run
        expect(subject.data).to include(:prop_data, :workplace)
      end

      it 'load properties to the :prop_data key' do
        subject.run
        expect(subject.data[:prop_data]).to eq properties
      end

      it 'sets %w[disabled_filters items_attributes] attributes' do
        subject.run
        expect(subject.data[:workplace]).to include('disabled_filters', 'items_attributes')
      end
    end
  end
end
