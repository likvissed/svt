require 'feature_helper'

module Invent
  module Items
    RSpec.describe Busy, type: :model do
      let!(:user) { create(:user) }
      let!(:workplaces) { create_list(:workplace_pk, 2, :add_items, items: %i[pc monitor monitor]) }
      let!(:items) { create_list(:item, 4, :with_property_values, type_name: 'monitor') }
      let(:type) { Type.find_by(name: :pc) }
      let(:item) { workplaces.first.items.first }
      let(:division) { item.workplace.division }

      subject { Busy.new(type.type_id, item.invent_num, item.barcode_item.id, division) }

      context 'without invent_num' do
        context 'and with barcode and without division' do
          subject { Busy.new('', '', item.barcode_item.id) }

          it 'loads items with specified barcode' do
            subject.run

            expect(subject.data[:items].count).to eq 1
            expect(subject.data[:items].first['item_id']).to eq item.item_id
          end

          context 'and when item have relations with warehouse_item' do
            let(:warehouse_item) do
              w_item = build(:new_item, warehouse_type: :without_invent_num, item_type: 'картридж', item_model: '6515DNI', count: 1)
              w_item.build_barcode_item
              w_item.save(validate: false)
              w_item
            end
            let(:item) do
              i_item = build(:item, :with_property_values, type_name: :printer)
              i_item.workplace = workplaces.first
              i_item.warehouse_items = [warehouse_item]
              i_item.save(validate: false)
              i_item
            end

            it 'shows item_type warehouse_item and count relations' do
              subject.run

              expect(subject.data[:items].first['warehouse_items'].count).to eq item.warehouse_items.count
              expect(subject.data[:items].first['warehouse_items'].first['item_type']).to eq warehouse_item.item_type
            end
          end

          context 'and when present warehouse_item with barcode' do
            let(:inv_item) { create(:item, :with_property_values, type_name: :printer) }
            let(:warehouse_item) do
              w_item = build(:new_item, warehouse_type: :without_invent_num, item_type: 'картридж', item_model: '6515DNI', count: 1)
              w_item.build_barcode_item
              w_item.item = inv_item

              w_item.save(validate: false)
              w_item
            end

            subject { Busy.new('', '', warehouse_item.barcode_item.id) }

            context 'when warehouse_item belongs to operation with processing status' do
              let!(:operation) { build(:order_operation, item_id: warehouse_item.id) }
              let!(:order) { create(:order, operation: :in, consumer_id_tn: user.id_tn, operations: [operation]) }

              its(:run) { is_expected.to be_falsey }

              it 'adds :item_already_used_in_orders error' do
                subject.run

                expect(subject.errors.details[:base]).to include(error: :item_already_used_in_orders, orders: order.id.to_s)
              end
            end

            context 'and when warehouse_item in property inv_item' do
              it 'loads items with specified barcode' do
                subject.run

                expect(subject.data[:items].count).to eq 1
                expect(subject.data[:items].first['id']).to eq warehouse_item.id
              end

              context 'and when inclide additional fields' do
                it 'adds :main_info and :codeable_type field to the each item' do
                  subject.run

                  expect(subject.data[:items].first).to include(:main_info, :codeable_type)
                end

                it 'output value in inclide additional fields' do
                  subject.run

                  expect(subject.data[:items].first[:codeable_type]).to eq warehouse_item.class.name.to_s.split('::').first.downcase
                  expect(subject.data[:items].first[:main_info]).to eq "#{warehouse_item.item_type} - #{warehouse_item.item_model}"
                end
              end
            end

            context 'and when warehouse_item in stock' do
              before { warehouse_item.item = nil }

              it 'loads items with specified barcode' do
                subject.run

                expect(subject.errors.details[:base]).to include(error: :item_not_found)
              end
            end
          end
        end

        context 'and without barcode' do
          subject { Busy.new(type.type_id, '', '') }

          it 'returns false' do
            expect(subject.run).to be_falsey
          end
        end
      end

      context 'with division' do
        context 'and when item is not belong to division' do
          subject { Busy.new(type.type_id, item.invent_num, item.barcode_item.id, 123) }

          it 'does not show this item in result array' do
            subject.run
            expect(subject.data[:items]).to be_empty
          end
        end
      end

      context 'when item with specified fields' do
        it 'loads item with specified invent_num, type, invent_num and division' do
          subject.run

          expect(subject.data[:items].count).to eq 1
          expect(subject.data[:items].first['item_id']).to eq item.item_id
        end
      end

      context 'when inclide additional fields' do
        let(:invent_num) { item.invent_num.blank? ? 'инв. № отсутствует' : "инв. №: #{item.invent_num}" }

        it 'adds :main_info, :codeable_type, :warehouse_items and :full_item_model field to the each item' do
          subject.run

          expect(subject.data[:items].first).to include(:main_info, :codeable_type, :warehouse_items, 'full_item_model')
        end

        it 'output value in inclide additional fields' do
          subject.run

          expect(subject.data[:items].first[:codeable_type]).to eq item.class.name.to_s.split('::').first.downcase
          expect(subject.data[:items].first[:warehouse_items]).to eq item.warehouse_items
          expect(subject.data[:items].first[:main_info]).to eq "#{item.type.short_description} - #{invent_num}"
        end
      end

      context 'when item does not belong to any operation' do
        it 'shows this item in result array' do
          subject.run
          expect(subject.data[:items].first.as_json).to include({ item_id: item.id }.as_json)
        end
      end

      context 'when item does not exists' do
        subject { Busy.new(type.type_id, 'error_num', item.item_id, division) }

        its(:run) { is_expected.to be_falsey }

        it 'adds :item_not_found' do
          subject.run
          expect(subject.errors.details[:base]).to include(error: :item_not_found)
        end
      end

      context 'when item belongs to operation with processing status' do
        let!(:operation_1) { create(:order_operation, stockman_id_tn: user.id_tn, status: :done, inv_items: [item]) }
        let!(:operation_2) { create(:order_operation, inv_items: [item]) }
        let!(:order) { create(:order, operation: :in, consumer_id_tn: user.id_tn, operations: [operation_2]) }

        its(:run) { is_expected.to be_falsey }

        it 'adds :item_already_used_in_orders error' do
          subject.run
          expect(subject.errors.details[:base]).to include(error: :item_already_used_in_orders, orders: order.id.to_s)
        end
      end

      context 'when item belongs to operation with done status' do
        let!(:operation) { create(:order_operation, stockman_id_tn: user.id_tn, status: :done, inv_items: [item]) }

        it 'shows this item in result array' do
          subject.run
          expect(subject.data[:items].as_json.first).to include({ item_id: item.id }.as_json)
        end
      end
    end
  end
end
