require 'feature_helper'

module Warehouse
  module Supplies
    RSpec.describe Create, type: :model do
      let!(:user) { create(:user) }
      let(:type) { Invent::Type.find_by(name: :monitor) }
      let(:model) { type.models.last }
      let(:item_1_attr) { attributes_for(:new_item, invent_type_id: type.type_id, invent_model_id: model.model_id, item_type: type.short_description, item_model: model.item_model, count: 0) }
      let(:operation_1) { attributes_for(:supply_operation, item: item_1_attr, shift: 10) }
      let(:item_2_attr) { attributes_for(:new_item, warehouse_type: :without_invent_num, item_type: 'Клавиатура', item_model: 'ASUS', count: 0) }
      let(:operation_2) { attributes_for(:supply_operation, item: item_2_attr, shift: 20) }
      let(:allowed_item_keys) { %i[invent_type_id invent_model_id warehouse_type item_type item_model barcode invent_num_start invent_num_end] }
      let(:supply_params) do
        supply = attributes_for(:supply)
        # Оставляем в item только параметры, разрешенные в strong_params
        [operation_1, operation_2].each do |op|
          op[:item].keys.each { |key| op[:item].delete(key) unless allowed_item_keys.include?(key) }
        end
        supply[:operations_attributes] = [operation_1, operation_2]
        supply
      end
      subject { Create.new(user, supply_params) }

      context 'when operations_attributes is empty' do
        let(:supply_params) do
          supply = attributes_for(:supply)
          supply[:operations_attributes] = []
          supply
        end

        its(:run) { is_expected.to be_truthy }

        it 'creates supply' do
          expect { subject.run }.to change(Supply, :count).by(1)
        end
      end

      context 'when item does not exist' do
        its(:run) { is_expected.to be_truthy }

        it 'creates supply' do
          expect { subject.run }.to change(Supply, :count).by(1)
        end

        it 'creates operations' do
          expect { subject.run }.to change(Operation, :count).by(2)
        end

        it 'creates items' do
          expect { subject.run }.to change(Item, :count).by(2)
        end

        it 'sets status :non_used to warehouse_item' do
          subject.run

          expect(Item.last.status).to eq 'non_used'
        end

        it 'sets into the :count attribute value specified in the associated operation' do
          subject.run
          expect(Supply.last.items.first.count).to eq operation_1[:shift]
          expect(Supply.last.items.last.count).to eq operation_2[:shift]
        end
      end

      context 'when item with the same model already exists (and item is new)' do
        context 'and when item has :with_invent_num type' do
          let!(:existing_item) { create(:new_item, inv_type: type, inv_model: model, count: 5) }

          its(:run) { is_expected.to be_truthy }

          it 'creates supply' do
            expect { subject.run }.to change(Supply, :count).by(1)
          end

          it 'creates operations' do
            expect { subject.run }.to change(Operation, :count).by(2)
          end

          it 'creates all items' do
            expect { subject.run }.to change(Item, :count).by(2)
          end

          it 'does not change :count attribute of existing item' do
            expect { subject.run }.not_to change { existing_item.reload.count }
          end
        end

        context 'and when item has :without_invent_num type' do
          let!(:existing_item_1) { create(:new_item, warehouse_type: :without_invent_num, item_type: 'Мышь', item_model: 'ASUS', count: 5) }
          let!(:existing_item_2) { create(:new_item, warehouse_type: :without_invent_num, item_type: 'Клавиатура', item_model: 'ASUS', count: 7) }

          its(:run) { is_expected.to be_truthy }

          it 'creates supply' do
            expect { subject.run }.to change(Supply, :count).by(1)
          end

          it 'creates operations' do
            expect { subject.run }.to change(Operation, :count).by(2)
          end

          it 'creates only one item' do
            expect { subject.run }.to change(Item, :count).by(1)
          end

          it 'does not change first item' do
            expect { subject.run }.not_to change { existing_item_1.reload.count }
          end

          it 'sets status :non_used to warehouse_item' do
            subject.run

            expect(Item.last.status).to eq 'non_used'
          end

          it 'changes :count attribute of existing item and sets a new value for new item' do
            subject.run
            expect(Supply.last.items.last.count).to eq operation_1[:shift]
            expect(Supply.last.items.first.count).to eq operation_2[:shift] + existing_item_2.count
          end
        end
      end

      context 'and when item with the same model exists (and item has :used status)' do
        context 'and when item has :with_invent_num type' do
          let!(:item) { create(:item, :with_property_values, type_name: :monitor, model: model) }
          let!(:w_item) { create(:used_item, inv_item: item, count_reserved: 1) }

          its(:run) { is_expected.to be_truthy }

          it 'creates supply' do
            expect { subject.run }.to change(Supply, :count).by(1)
          end

          it 'creates operations' do
            expect { subject.run }.to change(Operation, :count).by(2)
          end

          it 'creates all items' do
            expect { subject.run }.to change(Item, :count).by(2)
          end

          it 'sets status :non_used to warehouse_item' do
            subject.run

            expect(Item.last.status).to eq 'non_used'
          end

          it 'sets into the :count attribute value specified in the associated operation' do
            subject.run
            expect(Supply.last.items.first.count).to eq operation_1[:shift]
            expect(Supply.last.items.last.count).to eq operation_2[:shift]
          end
        end

        context 'and when item has :without_invent_num type' do
          let!(:existing_item) { create(:used_item, warehouse_type: :without_invent_num, item_type: 'Мышь', item_model: 'ASUS', count: 1) }

          its(:run) { is_expected.to be_truthy }

          it 'creates supply' do
            expect { subject.run }.to change(Supply, :count).by(1)
          end

          it 'creates operations' do
            expect { subject.run }.to change(Operation, :count).by(2)
          end

          it 'creates all items' do
            expect { subject.run }.to change(Item, :count).by(2)
          end

          it 'sets status :non_used to warehouse_item' do
            subject.run

            expect(Item.last.status).to eq 'non_used'
          end

          it 'sets into the :count attribute value specified in the associated operation' do
            subject.run
            expect(Supply.last.items.first.count).to eq operation_1[:shift]
            expect(Supply.last.items.last.count).to eq operation_2[:shift]
          end
        end
      end
    end
  end
end
