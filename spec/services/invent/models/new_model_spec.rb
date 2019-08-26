require 'feature_helper'

module Invent
  module Models
    RSpec.describe NewModel, type: :model do
      include_examples 'includes field property_list_not_fixed'

      it 'adds :model and :types keys to the data variable' do
        subject.run
        expect(subject.data).to include(:model, :types)
      end

      it 'includes :properties and :property_lists keys into the :types' do
        subject.run
        expect(subject.data[:types].first).to include('properties')
      end

      it 'includes :property_lists key into the :properties' do
        subject.run
        expect(subject.data[:types][3]['properties'].first).to include('property_lists')
      end
    end
  end
end
