require 'feature_helper'

module Warehouse
  module Items
    RSpec.describe Create, type: :model do
      let!(:current_user) { create(:user) }
      let(:location) { build(:location) }
      let(:property_values) do
        prop_val = Array.wrap(attributes_for(:mb_property_values))
        prop_val << attributes_for(:ram_property_values)
      end
      let(:item_params) do
        item = attributes_for(:expanded_item)
        item['property_values_attributes'] = property_values
        item['location_attributes'] = location.as_json
        item
      end
      subject { Create.new(current_user, item_params) }

      its(:run) { is_expected.to be_truthy }

      include_examples 'include data[:item]'

      it 'update count for object' do
        expect { subject.run }.to change(Item, :count).by(1)
        expect { subject.run }.to change(Location, :count).by(1)
        expect { subject.run }.to change(PropertyValue, :count).by(property_values.count)
      end

      context 'when item_params is invalid' do
        context 'and when room is nil' do
          before { item_params['location_attributes']['room_id'] = nil }

          it 'adds :room_is_blank error' do
            subject.run

            expect(subject.error[:full_message]).to eq 'Комната не может отсутствовать'
          end
        end

        context 'and when item_model is nil' do
          before { item_params[:item_model] = nil }

          it 'adds :item_model_is_blank error' do
            subject.run

            expect(subject.error[:full_message]).to eq 'Модель (опред. авт.) не может быть пустым'
          end
        end
      end
    end
  end
end
