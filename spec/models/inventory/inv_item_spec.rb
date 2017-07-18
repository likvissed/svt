require 'rails_helper'

module Inventory
  RSpec.describe InvItem, type: :model do
    it { is_expected.to have_many(:inv_property_values).order(:property_id).with_foreign_key('item_id').dependent(:destroy) }
    it { is_expected.to have_many(:standart_changes).class_name('Standart::Discrepancy').with_foreign_key('item_id').dependent(:destroy) }

    it { is_expected.to belong_to(:inv_type).with_foreign_key('type_id') }
    it { is_expected.to belong_to(:workplace) }
    it { is_expected.to belong_to(:inv_model).with_foreign_key('model_id') }

    it { is_expected.to validate_presence_of(:type_id) }
    it { is_expected.to validate_presence_of(:invent_num) }

    it { is_expected.to validate_numericality_of(:type_id).is_greater_than(0).only_integer }

    it { is_expected.to delegate_method(:inv_properties).to(:inv_type) }

    it { is_expected.to accept_nested_attributes_for(:inv_property_values).allow_destroy(true) }

    describe '#presence_model' do
      context 'when item_type belongs to array InvItem::PRESENCE_MODEL_EXCEPT' do
        InvItem::PRESENCE_MODEL_EXCEPT.each do |type|
          context 'and when model is set' do
            include_examples 'item_valid_model' do
              let(:item) { build(:item_with_item_model, type_name: type) }
            end
          end

          context 'and when model is not set' do
            include_examples 'item_valid_model' do
              let(:item) { build(:item, type_name: type) }
            end
          end
        end
      end

      context 'when item_type is not part of array InvItem::PRESENCE_MODEL_EXCEPT' do
        context 'and when model_id is set' do
          include_examples 'item_valid_model' do
            let(:item) { build(:item_with_model_id, type_name: :monitor) }
          end
        end

        context 'and when item_model is set' do
          include_examples 'item_valid_model' do
            let(:item) { build(:item_with_item_model, type_name: :monitor) }
          end
        end

        context 'and when model is not set' do
          include_examples 'item_not_valid_model' do
            let(:item) { build(:item, :without_model_id, type_name: :monitor) }
          end
        end
      end
    end

    describe '#set_default_model' do
      context 'when model_id.zero?' do
        let(:item) { create(:item_with_item_model, type_name: :monitor) }

        it 'should set model_id to nil' do
          expect(item.model_id).to be_nil
        end
      end
    end

    describe '#check_property_value' do
      context 'when item_type belongs to array InvPropertyValue::PROPERTY_WITH_FILES' do
        context 'and when all parametrs are sets' do
          include_examples 'item_valid_model' do
            let(:item) { build(:item_with_item_model, :with_property_values, type_name: :pc) }
          end
        end

        context 'and when file is set and file params is not set' do
          include_examples 'item_valid_model' do
            let(:item) { build(:item_with_item_model, :without_property_values_and_with_file, type_name: :pc) }
          end
        end

        context 'and when file is not set and file params is set' do
          include_examples 'item_valid_model' do
            let(:item) { build(:item_with_item_model, :with_property_values_and_without_file, type_name: :pc) }
          end
        end

        context 'and whem file is not set and file params is not set' do
          include_examples 'item_not_valid_model' do
            let(:item) { build(:item_with_item_model, :without_property_values, type_name: :pc) }
          end
        end

        # context 'and when user set file to 'nil' and received data from Audit' do
        #   let!(:item) { create(:item_with_item_model, :with_property_values, type_name: :pc) }
        #   subject(:file) { file ActionDispatch::Http::UploadedFile.new(tempfile: File.new('#{Rails
        #     .root}/spec/fixtures/anyfile.txt'), filename: 'anyfile.txt') }
        #
        #   it 'must destroy file loaded before' do
        #     item.inv_property_values = item.inv_property_values.map do |val|
        #       val.value = '' if val.property_id == InvProperty.find_by(name: :config_file).property_id
        #
        #       val
        #     end
        #   end
        # end
      end

      context 'when item_type is not part of array InvItem::PRESENCE_MODEL_EXCEPT' do
        context 'and when all invent_property_values are sets' do
          include_examples 'item_valid_model' do
            let(:item) { build(:item_with_item_model, :with_property_values, type_name: :monitor) }
          end
        end

        context 'and when not all invent_property_values are sets' do
          include_examples 'item_not_valid_model' do
            let(:item) { build(:item_with_item_model, :without_property_values, type_name: :monitor) }
          end
        end
      end
    end
  end
end
