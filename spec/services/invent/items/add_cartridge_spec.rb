require 'feature_helper'

module Invent
  module Items
    RSpec.describe AddCartridge, type: :model do
      skip_users_reference

      let(:worker) { create(:shatunova_user) }
      let(:workplace) do
        wp = build(:workplace_pk, dept: ***REMOVED***, status: :confirmed)
        wp.save(validate: false)
        wp
      end
      let(:item) { create(:item, :with_property_values, type_name: :printer, status: :in_workplace, workplace: workplace) }
      let(:cartridge) do
        obj = {}
        obj[:item_id] = item.item_id
        obj['name_model'] = 'test model'
        obj['count'] = 2

        obj
      end
      let(:cartridge_type) { 'Картридж' }

      subject { AddCartridge.new(worker, cartridge) }

      it 'create count records' do
        expect { subject.run }.to change(Warehouse::Order, :count).by(cartridge['count'])
        expect { subject.run }.to change(Warehouse::Operation, :count).by(cartridge['count'] * cartridge['count'])
        expect { subject.run }.to change(Warehouse::Item, :count).by(cartridge['count'])

        expect { subject.run }.to change(PropertyValue, :count).by(cartridge['count'])
        expect { subject.run }.to change(Barcode, :count).by(cartridge['count'])
      end

      its(:run) { is_expected.to be_truthy }

      context 'when status item not :in_workplace' do
        let!(:item) { create(:item, :with_property_values, type_name: :printer, status: :in_stock) }

        it 'adds :item_status_not_in_workplace error' do
          subject.run

          expect(subject.error[:full_message]).to eq(I18n.t('activemodel.errors.models.invent/items/add_cartridge.item_status_not_in_workplace'))
        end
      end

      context 'when not create order :in' do
        context 'and when count is zero' do
          before { cartridge['count'] = 0 }

          it 'adds :at_least_one_operation_for_workplace error' do
            subject.run

            expect(subject.error[:full_message]).to eq('Необходимо добавить хотя бы одну позицию с рабочего места №1')
          end
        end

        context 'and when count is zero' do
          before { cartridge['name_model'] = '' }

          it 'adds :operations.item_model is blank error' do
            subject.run

            expect(subject.error[:full_message]).to eq('Модель не может быть пустым. Модель (опред. авт.) не может быть пустым')
          end
        end
      end

      context 'when create and execute order :in' do
        let(:first_order_in) { Warehouse::Order.first }

        it 'create order :in with params' do
          subject.run

          expect(first_order_in.operation).to eq 'in'
          expect(first_order_in.status).to eq 'done'
          expect(first_order_in.invent_workplace_id).to eq item.workplace.workplace_id
        end

        it 'create operations for order :in' do
          subject.run

          expect(first_order_in.operations.count).to eq cartridge['count']

          first_order_in.operations.each do |op|
            expect(op.status).to eq 'done'
            expect(op.item_type).to eq cartridge_type
            expect(op.item_model).to eq cartridge['name_model']
            expect(op.shift).to eq(1)

            expect(op.item_id).not_to eq('')
          end
        end
      end

      context 'when create and execute order :out' do
        let(:second_order_out) { Warehouse::Order.second }

        it 'create order :out with params' do
          subject.run

          expect(second_order_out.operation).to eq 'out'
          expect(second_order_out.status).to eq 'done'
          expect(second_order_out.invent_workplace_id).to eq item.workplace.workplace_id
          expect(second_order_out.invent_num).to eq item.invent_num
        end

        it 'create operations for order :out' do
          subject.run

          expect(second_order_out.operations.count).to eq cartridge['count']

          second_order_out.operations.each do |op|
            expect(op.status).to eq 'done'
            expect(op.item_type).to eq cartridge_type
            expect(op.item_model).to eq cartridge['name_model']
            expect(op.shift).to eq(-1)

            expect(op.item_id).not_to eq('')
          end
        end

        it 'match the type and model for warehouse_item' do
          subject.run

          second_order_out.operations.each do |op|
            expect(op.item.item_type).to eq(cartridge_type)
            expect(op.item.item_model).to eq(cartridge['name_model'])
          end
        end

        it 'present barcode for warehouse_item' do
          subject.run

          second_order_out.operations.each do |op|
            expect(op.item.barcode_item.codeable_id).to eq op.item.id
          end
        end

        it 'create barcode as property for warehouse_item' do
          expect { subject.run }.to change(Barcode, :count).by(cartridge['count'])
        end

        it 'create invent_property_value as property for inv_item' do
          expect { subject.run }.to change(PropertyValue, :count).by(cartridge['count'])
        end
      end
    end
  end
end
