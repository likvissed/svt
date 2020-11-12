require 'feature_helper'

module Invent
  RSpec.describe PropertyValue, type: :model do
    it { is_expected.to have_one(:standard_discrepancy).class_name('Standard::Discrepancy') }
    it { is_expected.to belong_to(:property) }
    it { is_expected.to belong_to(:item) }
    it { is_expected.to belong_to(:property_list) }
    it { is_expected.to belong_to(:warehouse_item).with_foreign_key('warehouse_item_id').class_name('Warehouse::Item') }

    describe '#presence_val' do
      context 'when property_type is :string' do
        let(:item) { build(:item, type_name: :pc) }
        let(:property) { item.properties.where(property_type: :string).first }

        context 'and when value is set' do
          subject { build(:property_value, item: item, property: property, value: 'My value') }

          it { is_expected.to be_valid }
        end

        context 'and when value is not set' do
          subject { build(:property_value, item: item, property: property, property_list: property.property_lists.first) }

          it { is_expected.not_to be_valid }
          it 'has :blank error' do
            subject.valid?
            expect(subject.errors.details[:base].first).to include(error: :blank, empty_prop: property.short_description)
          end
        end
      end

      context 'when property_type is :list' do
        let(:item) { build(:item, type_name: :pc) }
        let(:property) { item.properties.where(property_type: :list).first }

        context 'and when property_list is set' do
          subject { build(:property_value, item: item, property: property, property_list: property.property_lists.first) }

          it { is_expected.to be_valid }
        end

        context 'and when property_list is not set' do
          subject { build(:property_value, item: item, property: property, value: 'My value') }

          it { is_expected.not_to be_valid }
          it 'has :blank error' do
            subject.valid?
            expect(subject.errors.details[:base].first).to include(error: :blank, empty_prop: property.short_description)
          end
        end
      end

      context 'when property_type is :list_plus' do
        let(:item) { build(:item, type_name: :monitor) }
        let(:property) { item.properties.where(property_type: :list_plus).first }

        context 'and when property_list is set' do
          subject { build(:property_value, item: item, property: property, property_list: property.property_lists.first) }

          it { is_expected.to be_valid }
        end

        context 'and when value is set' do
          subject { build(:property_value, item: item, property: property, value: 'My value') }

          it { is_expected.to be_valid }
        end

        context 'and when property_list and value are not sets' do
          subject { build(:property_value, item: item, property: property) }

          it { is_expected.not_to be_valid }
          it 'has :blank error' do
            subject.valid?
            expect(subject.errors.details[:base].first).to include(error: :blank, empty_prop: property.short_description)
          end
        end
      end

      context 'when property_type is unknown' do
        let(:item) { build(:item, type_name: :monitor) }
        let(:property) { Property.new(property_type: 'unknown', mandatory: true) }
        subject { build(:property_value, item: item, value: 'My value') }
        before { allow(subject).to receive(:property).and_return(property) }

        it { is_expected.not_to be_valid }
        it 'has :unknown_property_type error' do
          subject.valid?
          expect(subject.errors.details[:base].first).to include(error: :unknown_property_type)
        end
      end
    end

    describe '#need_validation?' do
      context 'when invent_num does not exist' do
        let(:item) { build(:item, type_name: :monitor, invent_num: nil) }
        let(:property) { item.properties.find_by(mandatory: false) }
        subject { build(:property_value, item: item, property: property) }

        it 'does not run :presence_val validation' do
          expect(subject).not_to receive(:presence_val)
          subject.valid?
        end
      end

      context 'when property is not :mandatory' do
        let(:item) { build(:item, type_name: :printer) }
        let(:property) { item.properties.find_by(mandatory: false) }
        subject { build(:property_value, item: item, property: property) }

        it 'does not run :presence_val validation' do
          expect(subject).not_to receive(:presence_val)
          subject.valid?
        end
      end

      context 'when property included into the Property::PROP_MANDATORY_EXCEPT constant' do
        Property::PROP_MANDATORY_EXCEPT.each do |prop_name|
          # Модель должна быть обязательно
          let(:item) { build(:item, item_model: 'my model', invent_num: invent_num, type_name: :notebook) }
          let(:property) { item.properties.find_by(name: prop_name) }
          subject { build(:property_value, item: item, property: property) }

          context 'and when invent_num included into exception' do
            # Инв. № из списка исключений
            let(:invent_num) { PcException.pluck(:invent_num).first }

            it 'does not run :presence_val validation' do
              expect(subject).not_to receive(:presence_val)
              subject.valid?
            end
          end

          context 'and when invent_num not included into exception' do
            let(:invent_num) { 'test_num' }

            it 'runs :presence_val validation' do
              expect(subject).to receive(:presence_val)
              subject.valid?
            end
          end
        end
      end

      context 'when type of item included into the Type::PRESENCE_MODEL_EXCEPT constant' do
        Type::PRESENCE_MODEL_EXCEPT.each do |type_name|
          # Убрали модель из item
          let(:item) { build(:item, model: nil, type_name: type_name) }
          let(:property) { item.properties.find_by(mandatory: true) }
          subject { build(:property_value, item: item, property: property) }

          it 'does not run "item.model_exists?" method' do
            expect(item).not_to receive(:model_exists?)
            subject.valid?
          end

          it 'runs :presence_val validation' do
            expect(subject).to receive(:presence_val)
            subject.valid?
          end
        end
      end
    end
  end
end
