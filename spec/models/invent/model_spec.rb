require 'feature_helper'

module Invent
  RSpec.describe Model, type: :model do
    it { is_expected.to have_many(:model_property_lists).dependent(:destroy) }
    it { is_expected.to have_many(:items).dependent(:restrict_with_error) }
    it { is_expected.to belong_to(:vendor) }
    it { is_expected.to belong_to(:type) }

    describe '#property_list_for' do
      let(:type) { Type.find_by(name: :monitor) }
      subject { type.models.first }
      let(:property) { type.properties.find_by(name: :diagonal) }

      context 'when property_list exists' do
        let(:prop_list) { subject.model_property_lists.find_by(property: property).property_list }

        it 'returns property_list object for selected model and property' do
          expect(subject.property_list_for(property)).to eq prop_list
        end
      end

      context 'when property_lsit is not exist' do
        before { allow(subject.model_property_lists).to receive(:find_by).and_return(nil) }

        it 'returns nil' do
          expect(subject.property_list_for(property)).to be_nil
        end
      end
    end
  end
end
