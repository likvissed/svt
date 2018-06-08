require 'feature_helper'

module Invent
  module Models
    RSpec.describe Create, type: :model do
      let(:type) { :printer }
      let(:properties) { Type.find_by(name: type).properties.includes(:property_lists) }
      let(:attributes) do
        properties.map.each_with_index do |prop, index|
          next if %w[list list_plus].exclude?(prop.property_type) || !prop.mandatory

          if index.zero?
            {
              property_id: nil,
              property_list_id: nil
            }
          else
            {
              property_id: prop.property_id,
              property_list_id: prop.property_lists.first.property_list_id
            }
          end
        end.compact
      end
      let(:model_params) do
        model = attributes_for(:model, type_id: Type.find_by(name: type).type_id, vendor_id: Vendor.first.vendor_id)
        model[:model_property_lists_attributes] = attributes
        model
      end
      subject { Create.new(model_params.as_json) }

      its(:run) { is_expected.to be_truthy }

      it 'creates model' do
        expect { subject.run }.to change(Model, :count).by(1)
      end

      it 'creates only those model_property_lists in which there is a field property_list_id' do
        expect { subject.run }.to change(ModelPropertyList, :count).by(2)
      end

      it 'sets item_model' do
        expect_any_instance_of(Model).to receive(:fill_item_model)
        subject.run
      end

      it 'broadcasts to models' do
        expect(subject).to receive(:broadcast_models)
        subject.run
      end

      context 'when model was not saved' do
        before { allow_any_instance_of(Model).to receive(:save).and_return(false) }

        its(:run) { is_expected.to be_falsey }

        it 'adds :object and :full_message keys to the error object' do
          subject.run
          expect(subject.error).to include(:object, :full_message)
        end
      end
    end
  end
end
