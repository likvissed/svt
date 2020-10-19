require 'feature_helper'

module Invent
  RSpec.describe Item, type: :model do
    it { is_expected.to have_one(:warehouse_item).with_foreign_key('invent_item_id').class_name('Warehouse::Item').dependent(:nullify) }
    it { is_expected.to have_many(:property_values).inverse_of(:item).dependent(:destroy).order('invent_property.property_order') }
    it { is_expected.to have_many(:standard_discrepancies).class_name('Standard::Discrepancy').dependent(:destroy) }
    it { is_expected.to have_many(:standard_logs).class_name('Standard::Log') }
    it { is_expected.to have_many(:warehouse_inv_item_to_operations).class_name('Warehouse::InvItemToOperation').with_foreign_key('invent_item_id').dependent(:destroy) }
    it { is_expected.to have_many(:warehouse_operations).through(:warehouse_inv_item_to_operations).class_name('Warehouse::Operation').source(:operation) }
    it { is_expected.to have_many(:warehouse_orders).through(:warehouse_operations).class_name('Warehouse::Order').source(:operationable) }
    it { is_expected.to have_many(:barcodes).dependent(:destroy) }
    it { is_expected.to belong_to(:type) }
    it { is_expected.to belong_to(:workplace) }
    it { is_expected.to belong_to(:model) }
    it { is_expected.to validate_presence_of(:invent_num) }
    it { is_expected.to delegate_method(:properties).to(:type) }
    it { is_expected.to accept_nested_attributes_for(:property_values).allow_destroy(true) }

    context 'when status is :waiting_take' do
      before { subject.status = :waiting_take }

      it { is_expected.not_to validate_presence_of(:invent_num) }
    end

    describe '#presence_model' do
      context 'when item_type belongs to array Type::PRESENCE_MODEL_EXCEPT' do
        Type::PRESENCE_MODEL_EXCEPT.each do |type|
          context 'and when model is set' do
            subject { build(:item, :with_property_values, item_model: 'my model', type_name: type) }

            it { is_expected.to be_valid }
          end

          context 'and when model is not set' do
            subject { build(:item, :with_property_values, model: nil, type_name: type) }

            it { is_expected.to be_valid }
          end
        end
      end

      context 'when item_type is not part of array Type::PRESENCE_MODEL_EXCEPT' do
        context 'and when model_id is set' do
          subject { build(:item, :with_property_values, type_name: :monitor) }

          it { is_expected.to be_valid }
        end

        context 'and when item_model is set' do
          subject { build(:item, :with_property_values, model: nil, item_model: 'my model', type_name: :monitor) }

          it { is_expected.to be_valid }
        end

        context 'and when model_id and item_model is not set' do
          subject { build(:item, :with_property_values, model: nil, type_name: :monitor) }

          it { is_expected.not_to be_valid }
          it 'adds :blank error to the :base key' do
            subject.valid?
            expect(subject.errors.details[:model].first).to include(error: :blank)
          end
        end
      end
    end

    describe '#set_default_model' do
      context 'when model_id.zero?' do
        let(:item) { create(:item, :with_property_values, model: nil, item_model: 'my model', type_name: :monitor) }

        it 'should set model_id to nil' do
          expect(item.model_id).to be_nil
        end
      end
    end

    describe '#check_mandatory' do
      context 'when all properties with mandatory flag are sets' do
        subject { build(:item, :with_property_values, type_name: :printer) }

        it { is_expected.to be_valid }
      end

      context 'when not all properties with mandatory flag are sets' do
        subject { build(:item, type_name: :printer) }

        it { is_expected.not_to be_valid }

        it 'includes the { base: :property_not_filled error } error for each property_value with mandatory flag' do
          subject.valid?
          subject.properties.where(mandatory: true).find_each do |prop|
            expect(subject.errors.details[:base]).to include(error: :property_not_filled, empty_prop: prop.short_description)
          end
        end

        context 'and when flag disable_filters is set' do
          before { subject.disable_filters = true }

          it { is_expected.to be_valid }
        end
      end

      context 'when all properties with mandatory flag exists but not filled' do
        subject do
          item = build(:item, :with_property_values, type_name: :printer)
          item.property_values.first.property_list_id = 0
          item
        end

        it 'does not add :property_not_filled error' do
          subject.valid?

          subject.properties.where(mandatory: true).find_each do |prop|
            expect(subject.errors.details[:base]).not_to include(error: :property_not_filled, empty_prop: prop.short_description)
          end
        end
      end
    end

    describe '#model_exists?' do
      context 'when model is set' do
        subject { build(:item, type_name: :monitor) }

        its(:model_exists?) { is_expected.to be_truthy }
      end

      context 'when item_model is set' do
        subject { build(:item, model: nil, item_model: 'my model', type_name: :monitor) }

        its(:model_exists?) { is_expected.to be_truthy }
      end

      context 'when model and item_model are not sets' do
        subject { build(:item, model: nil, type_name: :monitor) }

        its(:model_exists?) { is_expected.to be_falsey }
      end
    end

    describe '#to_stock!' do
      subject { create(:item, :with_property_values, type_name: :ups, workplace_id: 123, status: :in_workplace, priority: :high) }
      before { subject.to_stock! }

      it 'sets nil to the workplace_id attribute' do
        expect(subject.workplace).to be_nil
      end

      it 'sets :in_stock to the status attribute' do
        expect(subject.status).to eq 'in_stock'
      end

      it 'sets :default to the priority attribute' do
        expect(subject.priority).to eq 'default'
      end
    end

    describe '#full_item_model' do
      context 'when type is :pc' do
        let(:item_model) do
          properties = Property.where(name: Property::FILE_DEPENDING)
          subject.property_values.where(property: properties).map(&:value).join(' / ')
        end

        context 'and when values is present' do
          subject { create(:item, :with_property_values, type_name: :pc) }

          it 'loads all config parameters' do
            expect(subject.full_item_model).to eq item_model
          end
        end

        context 'and when item_model is present' do
          let(:str_item_model) { 'UNIT 1' }
          subject { create(:item, :with_property_values, item_model: str_item_model, type_name: :pc) }

          it 'loads item_model and config parameters' do
            expect(subject.full_item_model).to eq "#{str_item_model}: #{item_model}"
          end
        end

        context 'and when values is blank' do
          subject do
            i = build(:item, :without_property_values, type_name: :pc, disable_filters: true)
            i.save(validate: false)
            i
          end

          it 'removes skips blank values' do
            expect(subject.full_item_model).to eq 'Конфигурация отсутствует'
          end
        end
      end

      context 'when type is not :pc' do
        subject { build(:item, type_name: :monitor) }

        it 'runs :short_item_model method' do
          expect(subject).to receive(:short_item_model)
          subject.full_item_model
        end
      end
    end

    describe '#short_item_model' do
      context 'when model exists' do
        subject { build(:item, type_name: :monitor) }

        it 'returns value from model.item_model' do
          expect(subject.full_item_model).to eq subject.model.item_model
        end
      end

      context 'when item_model exists' do
        subject { build(:item, type_name: :monitor, model: nil, item_model: 'My model') }

        it 'returns value from item_model' do
          expect(subject.full_item_model).to eq subject.item_model
        end
      end
    end

    describe '#get_value' do
      let(:type) { :printer }
      let(:property) { Invent::Type.find_by(name: type).properties.find_by(name: :date) }
      subject { create(:item, :with_property_values, type_name: type) }

      context 'when value stored into property_value table' do
        let(:expected_value) { subject.property_values.find_by(property: property).value }

        include_examples 'for #get_value specs'
      end

      context 'when value stored into property_list table' do
        let(:property) { Invent::Type.find_by(name: type).properties.find_by(name: :connection_type) }
        let(:expected_value) { subject.property_values.find_by(property: property).property_list.short_description }

        include_examples 'for #get_value specs'
      end

      context 'when property is another type' do
        it 'raises a RuntimeError error' do
          expect { subject.get_value('another') }.to raise_error(RuntimeError, 'Неизвестный тип свойства')
        end
      end

      context 'when result array has one value' do
        it 'return only single value' do
          expect(subject.get_value(property)).to be_a(String)
        end
      end

      context 'when result does not have any value' do
        let(:property) { Invent::Type.find_by(name: :monitor).properties.find_by(name: :diagonal) }

        it 'returns nil' do
          expect(subject.get_value(property)).to be_nil
        end
      end

      context 'when result has more that one value' do
        let(:prop_val) { property.property_values.first }

        it 'returns array of values' do
          allow(subject.property_values).to receive_message_chain(:includes, :where, :find_each).and_yield(prop_val).and_yield(prop_val)
          expect(subject.get_value(property).size).to eq 2
        end
      end
    end

    describe '#build_property_values' do
      let(:warehouse_item) { create(:expanded_item) }
      context 'when type is not exist' do
        subject { build(:item, type: nil) }

        it 'returns nil' do
          expect(subject.build_property_values(warehouse_item, true)).to be_nil
        end
      end

      context 'when created item which has additional properties' do
        let(:notebook_type) { Type.find_by(name: :notebook) }
        subject { build(:item, type: notebook_type) }

        context 'when adds item with filled :value' do
          let(:warehouse_item_with_prop_val) { create(:item_with_property_values) }
          let(:ram) { Property.find_by(name: 'ram') }

          before { subject.build_property_values(warehouse_item_with_prop_val, true) }

          it 'create property_values with all properties' do
            subject.save(validate: false)

            subject.property_values.each do |prop_val|
              expect(subject.property_values.find_by(property_id: prop_val.property_id).property_id).to eq prop_val.property_id
            end
          end

          it 'create property_value with filled :value' do
            subject.save(validate: false)

            warehouse_item_with_prop_val.property_values.each do |prop_val|
              if prop_val.property_id == ram.property_id
                expect(subject.property_values.find_by(property_id: prop_val.property_id).value).to eq("#{prop_val.value} Гб")
              else
                expect(subject.property_values.find_by(property_id: prop_val.property_id).value).to eq prop_val.value
              end
            end
          end

          it 'increment count of PropertyValue' do
            expect { subject.save(validate: false) }.to change { PropertyValue.count }.by(notebook_type.properties.count)
          end
        end

        context 'and when adds item with blank value for property_value' do
          before { subject.build_property_values(warehouse_item, true) }

          it 'fills with empty values' do
            subject.save(validate: false)

            notebook_type.properties.each_with_index do |_prop, index|
              expect(subject.property_values[index].value).to eq('')
            end
          end
        end
      end

      context 'when type exists' do
        let(:printer_type) { Type.find_by(name: :printer) }

        context 'and when model exists' do
          subject { build(:item, type: printer_type) }
          before { subject.build_property_values(warehouse_item, true) }

          it 'creates one property_value for each property' do
            expect(subject.property_values.size).to eq printer_type.properties.size
          end

          it 'sets default value for each property specified by selected model' do
            subject.save(validate: false)
            printer_type.properties.each do |prop|
              if prop.property_type == 'string'
                expect(subject.get_value(prop)).to be_empty
              elsif %w[list list_plus].include?(prop.property_type)
                expect(subject.get_value(prop)).to eq subject.model.property_list_for(prop).try(:short_description).to_s
              end
            end
          end
        end

        context 'and when model is not exist' do
          subject { build(:item, type: printer_type, model: nil) }
          before { subject.build_property_values(warehouse_item, true) }

          it 'creates one property_value for each property' do
            expect(subject.property_values.size).to eq printer_type.properties.size
          end

          it 'sets empty values for each property with string :property_type' do
            subject.property_values.each do |prop_val|
              expect(prop_val.value).to be_empty
              expect(prop_val.property_list).to be_nil
            end
          end
        end
      end
    end

    describe '#need_battery_replacement?' do
      Invent::Type.where.not(name: :ups).each do |type|
        context "when item type is #{type.name}" do
          subject { build(:item, priority: :high, type: type) }

          its(:need_battery_replacement?) { is_expected.to be_falsey }
        end
      end

      context 'when item type is :ups' do
        let(:prop) { Invent::Property.find_by(name: :replacement_date) }
        subject { create(:item, :with_property_values, priority: :high, type_name: :ups) }
        before { subject.property_values.find_by(property_id: prop.property_id).update_attribute(:value, new_date) }

        context 'and when battery was replaced less than 3 years ago' do
          let(:new_date) { Time.zone.now - 2.years }

          its(:need_battery_replacement?) { is_expected.to be_falsey }
        end

        context 'and when battery was replaced more than 3 years ago' do
          let(:new_date) { Time.zone.now - 4.years }
          let(:expected) do
            {
              type: :warning,
              years: Item::LEVELS_BATTERY_REPLACEMENT[:warning]
            }
          end

          it 'returns object with :warning type and count of years' do
            expect(subject.need_battery_replacement?).to eq expected
          end
        end

        context 'and when battery was replaced more than 5 years ago' do
          let(:new_date) { Time.zone.now - 6.years }
          let(:expected) do
            {
              type: :critical,
              years: Item::LEVELS_BATTERY_REPLACEMENT[:critical]
            }
          end

          it 'returns object with type :critical type and count of years' do
            expect(subject.need_battery_replacement?).to eq expected
          end
        end
      end
    end

    describe '#was_changed?' do
      subject { create(:item, :with_property_values, type_name: :monitor) }
      before do
        # Далее обновления, чтобы правильно отработал метод attribute_before_last_save внутри метода #was_changed?
        subject.update(create_time: Time.zone.now)
        subject.property_values.first.update(create_time: Time.zone.now)
      end

      context 'when model was changed' do
        before { subject.model = Invent::Model.last }

        its(:was_changed?) { is_expected.to be_truthy }
      end

      context 'when item_model was changed' do
        before { subject.item_model = 'new_item_model' }

        its(:was_changed?) { is_expected.to be_truthy }
      end

      context 'when property_list_id was changed' do
        before { subject.property_values.first.property_list_id = 123_123 }

        its(:was_changed?) { is_expected.to be_truthy }
      end

      context 'when value was changed' do
        before { subject.property_values.first.value = 'new_value' }

        its(:was_changed?) { is_expected.to be_truthy }
      end

      context 'when nothing was changed' do
        its(:was_changed?) { is_expected.to be_falsey }
      end
    end

    describe '#prevent_destroy' do
      its(:destroy) { is_expected.to be_truthy }

      context 'when item has operation with :processing status' do
        let!(:order) { create(:order, :default_workplace) }
        subject { order.inv_items.first }

        it 'does not destroy Item' do
          expect { subject.destroy }.not_to change(Item, :count)
        end

        it 'does not destroy warehouse_inv_item_to_operations' do
          expect { subject.destroy }.not_to change(Warehouse::InvItemToOperation, :count)
        end

        it 'adds :cannot_destroy_with_processing_operation error' do
          subject.destroy
          expect(subject.errors.details[:base]).to include(error: :cannot_destroy_with_processing_operation, order_id: order.id)
        end
      end
    end

    describe '#prevent_update' do
      let!(:item) { create(:item, :with_property_values, type_name: :printer) }
      subject { item }

      context 'when warehouse_item does not exist' do
        it 'allows update any attribute' do
          expect { subject.update(item_model: 'new_item_model', model: nil) }.to change { subject.reload.item_model }.to('new_item_model')
        end
      end

      context 'when warehouse_item exists' do
        let!(:w_item) { create(:used_item, inv_item: subject, invent_num_end: 200) }

        context 'and when model was changed' do
          it 'does not update item' do
            expect { subject.update(model: Model.last) }.not_to change { subject.reload.model }
          end

          it 'adds :cannot_update_item_due_warehouse_item' do
            subject.update(model: Model.last)

            expect(subject.errors.details[:model]).to include(error: :cannot_update_due_warehouse_item)
          end
        end

        context 'and when item_model was changed' do
          it 'does not update item' do
            expect { subject.update(item_model: 'new_item_model', model: nil) }.not_to change { subject.reload.item_model }
          end

          it 'adds :cannot_update_item_due_warehouse_item' do
            subject.update(item_model: 'new_item_model', model: nil)

            expect(subject.errors.details[:item_model]).to include(error: :cannot_update_due_warehouse_item)
          end
        end

        context 'and when type_id was changed' do
          it 'does not update item' do
            expect { subject.update(type: Type.last) }.not_to change { subject.reload.type }
          end

          it 'adds :cannot_update_item_due_warehouse_item' do
            subject.update(type: Type.last)

            expect(subject.errors.details[:type]).to include(error: :cannot_update_due_warehouse_item)
          end
        end

        context 'and when other attribute was changed' do
          it 'updates data' do
            expect { subject.update(serial_num: 'new_serial_num') }.to change { subject.reload.serial_num }
          end
        end
      end
    end

    describe '#set_default_values' do
      context 'when priority already exists' do
        subject { build(:item, :with_property_values, type_name: :monitor, priority: :high) }

        it 'does not change priority' do
          subject.save
          expect(subject.reload.priority).to eq 'high'
        end
      end

      context 'when priority is not exist' do
        subject { build(:item, :with_property_values, type_name: :monitor) }

        it 'sets default priority' do
          subject.save
          expect(subject.reload.priority).to eq 'default'
        end
      end
    end

    describe '#invent_num_from_allowed_pool_of_numbers' do
      context 'when item is new' do
        subject { build(:item, :with_property_values, type_name: :monitor, priority: :high) }

        it { is_expected.to be_valid }
      end

      context 'when item from supply' do
        context 'and when warehouse_item has invent_num_start' do
          let(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
          let!(:new_item) { create(:new_item, count: 4, inv_type: Invent::Type.find_by(name: :pc), item_model: 'UNIT') }
          let(:operation) { attributes_for(:order_operation, item_id: new_item.id, shift: -1) }
          before do
            order_params = attributes_for(:order, operation: :out, invent_workplace_id: workplace.workplace_id)
            order_params[:operations_attributes] = [operation]
            Warehouse::Orders::CreateOut.new(create(:***REMOVED***_user), order_params.as_json).run
          end

          context 'and when invent_num from allowed pool' do
            subject { Item.last }

            it { is_expected.to be_valid }
          end

          context 'and when invent_num not from allowed pool' do
            context 'and when invent_num was changed' do
              subject do
                item = Item.last
                item.invent_num = '333'
                item
              end

              it 'adds :not_from_allowed_pool error' do
                subject.valid?
                expect(subject.errors.details[:invent_num]).to include(error: :not_from_allowed_pool, start_num: new_item.invent_num_start, end_num: new_item.invent_num_end)
              end
            end

            context 'and when invent_num not was changed' do
              subject do
                item = Item.last
                item.invent_num = '333'
                item.save(validate: false)
                item
              end

              it { is_expected.to be_valid }
            end
          end
        end

        context 'and when warehouse_item does not have invent_num_start' do
          let(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
          let!(:new_item) do
            i = build(:new_item, count: 4, inv_type: Invent::Type.find_by(name: :pc), item_model: 'UNIT', invent_num_start: 0, invent_num_end: 0)
            i.save(validate: false)
            i
          end
          let(:operation) { attributes_for(:order_operation, item_id: new_item.id, shift: -1) }
          before do
            order_params = attributes_for(:order, operation: :out, invent_workplace_id: workplace.workplace_id)
            order_params[:operations_attributes] = [operation]
            Warehouse::Orders::CreateOut.new(create(:***REMOVED***_user), order_params).run
          end
          subject { Item.last }

          it 'allows to set custom invent_num' do
            subject.invent_num = '333'
            expect(subject.valid?).to be_truthy
          end
        end
      end

      context 'when item without supply' do
        let!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
        subject { workplace.items.first }
        before { subject.invent_num = 'new_num' }

        it { is_expected.to be_valid }
      end
    end

    # describe '#model_id_nil_if_model_item' do
    #   context 'when model is set' do
    #     let!(:item) { create(:item, :with_property_values, type_name: :printer) }
    #     before { item.item_model = 'new_printer_model' }

    #     it 'sets empty string to item_model' do
    #       item.save

    #       expect(item.reload.item_model).to be_empty
    #     end
    #   end

    #   context 'when model is empty' do
    #     let!(:item) { create(:item, :with_property_values, type_name: :printer, model: nil, item_model: 'old_printer_model') }
    #     before { item.item_model = 'new_printer_model' }

    #     it 'does not set empty string to item_model' do
    #       item.save

    #       expect(item.reload.item_model).to eq 'new_printer_model'
    #     end
    #   end
    # end
  end
end
