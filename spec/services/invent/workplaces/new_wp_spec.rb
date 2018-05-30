require 'feature_helper'

module Invent
  module Workplaces
    RSpec.describe NewWp, type: :model do
      let(:user) { create(:user) }
      let(:workplace_count) { create(:active_workplace_count, users: [user]) }
      subject { NewWp.new(user) }

      it 'fills the @data with %w[prop_data divisioins] keys' do
        subject.run
        expect(subject.data).to include(:prop_data, :divisions)
      end

      let(:properties) do
        prop = LkInvents::InitProperties.new
        prop.run
        prop.data
      end

      it 'load properties to the :prop_data key' do
        subject.run
        expect(subject.data[:prop_data]).to eq properties
      end

      it 'load all divisions to the :divisions key' do
        subject.run
        expect(subject.data[:divisions].length).to eq WorkplaceCount.count
      end
    end
  end
end
