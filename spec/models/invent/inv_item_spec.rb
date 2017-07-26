require 'rails_helper'

module Invent
  RSpec.describe InvItem, type: :model do
    it { is_expected.to have_many(:inv_property_values).with_foreign_key('item_id').dependent(:destroy) }
    it { is_expected.to have_many(:standart_discrepancies).class_name('Standart::Discrepancy').with_foreign_key('item_id').dependent(:destroy) }
    it { is_expected.to have_many(:standart_logs).class_name('Standart::Log').with_foreign_key('item_id') }

    it { is_expected.to belong_to(:inv_type).with_foreign_key('type_id') }
    it { is_expected.to belong_to(:workplace) }
    it { is_expected.to belong_to(:inv_model).with_foreign_key('model_id') }

    it { is_expected.to validate_presence_of(:type_id) }
    it { is_expected.to validate_presence_of(:invent_num) }

    it { is_expected.to validate_numericality_of(:type_id).is_greater_than(0).only_integer }

    it { is_expected.to delegate_method(:inv_properties).to(:inv_type) }

    it { is_expected.to accept_nested_attributes_for(:inv_property_values).allow_destroy(true) }

    let(:workplace_count) { create :active_workplace_count, :default_user }
    let(:secret_workplace) do
      build :workplace_pk,
            workplace_count: workplace_count,
            workplace_specialization: WorkplaceSpecialization.find_by(name: :secret)
    end
    let(:common_workplace) do
      build :workplace_pk,
            workplace_count: workplace_count,
            workplace_specialization: WorkplaceSpecialization.find_by(name: :other)
    end

    describe '#presence_model' do
      context 'when item_type belongs to array InvType::PRESENCE_MODEL_EXCEPT' do
        InvType::PRESENCE_MODEL_EXCEPT.each do |type|
          context 'and when model is set' do
            include_examples 'item_valid_model' do
              let(:item) { build(:item_with_item_model, :with_property_values, type_name: type, workplace: common_workplace) }
            end
          end

          context 'and when model is not set' do
            include_examples 'item_valid_model' do
              let(:item) { build(:item, :with_property_values, type_name: type, workplace: common_workplace) }
            end
          end
        end
      end

      context 'when item_type is not part of array InvType::PRESENCE_MODEL_EXCEPT' do
        context 'and when model_id is set' do
          include_examples 'item_valid_model' do
            let(:item) { build(:item_with_model_id, :with_property_values, type_name: :monitor, workplace: common_workplace) }
          end
        end

        context 'and when item_model is set' do
          include_examples 'item_valid_model' do
            let(:item) { build(:item_with_item_model, :with_property_values, type_name: :monitor, workplace: common_workplace) }
          end
        end

        context 'and when model is not set' do
          let(:item) { build(:item, :without_model_id, :with_property_values, type_name: :monitor, workplace: common_workplace) }

          include_examples 'item_not_valid_model'

          it 'includes the model_id: :blank error' do
            item.valid?
            expect(item.errors.details[:model_id]).to include(error: :blank)
          end
        end
      end
    end

    describe '#set_default_model' do
      context 'when model_id.zero?' do
        let(:item) { create(:item_with_item_model, :with_property_values, type_name: :monitor) }

        it 'should set model_id to nil' do
          expect(item.model_id).to be_nil
        end
      end
    end

    describe '#check_property_value' do
      context 'when item_type belongs to array InvType::TYPE_WITH_FILES' do
        context 'and when workplace_specialization != "secret"' do
          context 'and when all parametrs are sets' do
            include_examples 'item_valid_model' do
              let(:item) { build(:item_with_item_model, :with_property_values, type_name: :pc, workplace: common_workplace) }
            end
          end

          context 'and when file is set and file params is not set' do
            include_examples 'item_valid_model' do
              let(:item) { build(:item_with_item_model, :without_property_values_and_with_file, type_name: :pc, workplace: common_workplace) }
            end
          end

          context 'and when file is not set and file params is set' do
            include_examples 'item_valid_model' do
              let(:item) { build(:item_with_item_model, :with_property_values_and_without_file, type_name: :pc, workplace: common_workplace) }
            end
          end

          context 'and when file is not set and file params is not set' do
            let(:item) { build(:item_with_item_model, :without_property_values, type_name: :pc, workplace: common_workplace) }

            include_examples 'item_not_valid_model'

            it 'includes the base: :pc_data_not_received error' do
              item.valid?
              expect(item.errors.details[:base]).to include(error: :pc_data_not_received)
            end
          end
        end

        context 'and when workplace_specialization == "secret"' do
          let(:item) { build :item_with_item_model, :without_property_values, type_name: :pc, workplace: secret_workplace }
          let(:properties) { InvProperty.where(name: InvProperty::SECRET_EXCEPT) }

          it 'creates item without file and InvProperty::SECRET_EXCEPT properties' do
            item.valid?

            expect(item.errors.details[:base]).not_to include(error: :pc_data_not_received)
            properties.each do |prop|
              expect(item.errors.details[:base]).not_to include(error: :field_is_empty, empty_field: prop.short_description)
            end
          end
        end
      end

      context 'when item_type is not part of array InvType::TYPE_WITH_FILES' do
        context 'and when all parameters are sets' do
          include_examples 'item_valid_model' do
            let(:item) { build(:item_with_item_model, :with_property_values, type_name: :printer) }
          end
        end

        context 'and when not all invent_property_values are sets' do
          let(:item) { build(:item_with_item_model, :without_property_values, type_name: :printer) }

          include_examples 'item_not_valid_model'

          it 'includes the base: :field_is_empty error' do
            item.valid?
            item.inv_type.inv_properties.where(mandatory: true) do |prop|
              expect(item.errors.details[:base]).to include(error: :field_is_empty, empty_field: prop.short_description)
            end
          end
        end
      end
    end

    describe '#check_mandatory' do
      context 'when all properties with mandatory flag are sets' do
        include_examples 'item_valid_model' do
          let(:item) { build(:item_with_item_model, :with_property_values, type_name: :printer) }
        end
      end

      context 'when not all properties with mandatory flag are sets' do
        let(:item) { build(:item_with_item_model, type_name: :printer) }

        include_examples 'item_not_valid_model'

        it 'includes the base: :property_not_filled error' do
          item.valid?
          item.inv_type.inv_properties.where(mandatory: true) do |prop|
            expect(item.errors.details[:base]).to include(error: :property_not_filled, empty_field: prop.short_description)
          end
        end
      end
    end
  end
end
