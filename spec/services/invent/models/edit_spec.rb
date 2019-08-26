require 'feature_helper'

module Invent
  module Models
    RSpec.describe Edit, type: :model do
      let(:type) { :monitor }
      let(:properties) { Type.find_by(name: type).properties.includes(:property_lists) }
      let(:attributes) do
        properties.map do |prop|
          {
            property_id: prop.property_id,
            property_list_id: prop.property_lists.first.property_list_id
          }
        end
      end
      let!(:model) { create(:model, model_property_lists_attributes: attributes) }
      subject { Edit.new(model.model_id) }

      its(:run) { is_expected.to be_truthy }

      include_examples 'includes field property_list_not_fixed'

      it 'adds :model and :types keys to the data variable' do
        subject.run
        expect(subject.data).to include(:model, :types)
      end

      it 'adds :model_property_lists_attributes to the :model key' do
        subject.run
        expect(subject.data[:model]).to include('model_property_lists_attributes')
      end

      it 'includes :properties and :property_lists keys into the :types' do
        subject.run
        expect(subject.data[:types].first).to include('properties')
      end

      it 'includes :property_lists key into the :properties' do
        subject.run
        expect(subject.data[:types][3]['properties'].first).to include('property_lists')
      end

      it 'rename primary keys of :model_property_lists_attributes array' do
        subject.run
        subject.data[:model]['model_property_lists_attributes'].each do |prop_list|
          expect(prop_list).to include('id')
        end
      end
    end
  end
end
