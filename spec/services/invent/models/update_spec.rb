require 'feature_helper'

module Invent
  module Models
    RSpec.describe Update, type: :model do
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
      let!(:model) { create(:model, model_property_lists_attributes: attributes) }

      let(:model_params) do
        new_model = model.as_json(include: :model_property_lists)
        new_model['model_property_lists_attributes'] = new_model['model_property_lists']
        new_model['model_property_lists_attributes'].each do |prop_list|
          prop_list['id'] = prop_list['model_property_list_id']
          prop_list.delete('model_property_list_id')
        end
        new_model['item_model'] = 'Updated model'

        new_model.delete('model_property_lists')
        new_model
      end
      subject { Update.new(model.model_id, model_params.as_json) }

      its(:run) { is_expected.to be_truthy }

      it 'updates model data' do
        subject.run
        expect(model.reload.item_model).to eq 'Acer Updated model'
      end

      it 'broadcasts to models' do
        expect(subject).to receive(:broadcast_models)
        subject.run
      end

      it 'sets item_model' do
        expect_any_instance_of(Model).to receive(:fill_item_model)
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
