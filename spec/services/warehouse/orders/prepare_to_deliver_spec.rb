# require 'feature_helper'

# module Warehouse
#   module Orders
#     RSpec.describe PrepareToDeliver, type: :model do
#       let!(:current_user) { create(:***REMOVED***_user) }
#       subject { PrepareToDeliver.new(current_user, order.warehouse_order_id, order_params) }

#       context 'when operations belongs_to item' do
#         # Техника Б/У с инв. номером
#         let(:first_inv_item) { create(:item, :with_property_values, type_name: :pc, status: :waiting_take) }
#         let(:sec_inv_item) { create(:item, :with_property_values, type_name: :monitor) }
#         # Техника новая, прикрепленная к РМ (и ожидающая выдачи)
#         let(:fourth_inv_item) { create(:item, type_name: :monitor, disable_filters: true, status: :waiting_take, invent_num: nil) }
#         let(:workplace) do
#           wp = build(:workplace_pk, items: [first_inv_item, sec_inv_item], dept: ***REMOVED***)
#           wp.save(validate: false)
#           wp
#         end
#         # Это будет выдаваться
#         let(:first_item) { create(:used_item, inv_item: first_inv_item) }
#         let(:sec_item) { create(:used_item, inv_item: sec_inv_item) }
#         # Это будет выдаваться
#         let(:third_item) { create(:used_item, warehouse_type: :without_invent_num, item_type: 'test type', item_model: 'test model') }
#         # Это будет выдаваться
#         let(:fourth_item) { create(:new_item, inv_item: nil, type: fourth_inv_item.type, model: fourth_inv_item.model, count: 3, count_reserved: 1) }
#         let(:operations) do
#           [
#             build(:order_operation, item: first_item, invent_item_id: first_item.invent_item_id),
#             build(:order_operation, item: sec_item, invent_item_id: sec_item.invent_item_id),
#             build(:order_operation, item: third_item),
#             build(:order_operation, item: fourth_item, invent_item_id: fourth_item.invent_item_id),
#           ]
#         end
#         let!(:order) { create(:order, workplace: workplace, operation: :out, operations: operations, inv_items: [first_inv_item, sec_inv_item, fourth_inv_item]) }
#         let(:order_json) { order.as_json }

#         context 'and when user selected items with different types' do
#           let(:order_params) do
#             order_json['consumer_tn'] = ***REMOVED***
#             order_json['operations_attributes'] = operations.as_json
#             order_json['operations_attributes'].each_with_index do |op, index|
#               op['status'] = 'done' if [0, 2, 3].include?(index)
#               op['id'] = op['warehouse_operation_id']
#               op['invent_item_id'] = operations.find { |el| el.warehouse_operation_id == op['id'] }.invent_item_id

#               op.delete('warehouse_operation_id')
#             end
#             order_json
#           end

#           include_examples 'prepare_to_deliver specs'

#           it 'sets id for each invent_item' do
#             subject.run
#             subject.data[:inv_items_attributes].each do |inv_item|
#               expect(inv_item).to include('id')
#             end
#           end
#         end

#         context 'and when user does not selected any operation' do
#           let(:order_params) do
#             order_json['consumer_tn'] = ***REMOVED***
#             order_json['operations_attributes'] = operations.as_json
#             order_json['operations_attributes'].each do |op|
#               op['id'] = op['warehouse_operation_id']
#               op['invent_item_id'] = operations.find { |el| el.warehouse_operation_id == op['id'] }.invent_item_id

#               op.delete('warehouse_operation_id')
#             end
#             order_json
#           end

#           it 'adds :operation_not_selected error' do
#             subject.run

#             expect(subject.error[:full_message]).to eq 'Необходимо выбрать хотя бы одну позицию'
#           end

#           its(:run) { is_expected.to be_falsey }
#         end

#         context 'and when user selected items with the same types' do
#           let(:order_params) do
#             order_json['consumer_tn'] = ***REMOVED***
#             order_json['operations_attributes'] = operations.as_json
#             order_json['operations_attributes'].each_with_index do |op, index|
#               op['status'] = 'done' if [0, 1, 2, 3].include?(index)
#               op['id'] = op['warehouse_operation_id']
#               op['invent_item_id'] = operations.find { |el| el.warehouse_operation_id == op['id'] }.invent_item_id

#               op.delete('warehouse_operation_id')
#             end
#             order_json
#           end

#           include_examples 'prepare_to_deliver specs'
#         end
#       end
#     end
#   end
# end
