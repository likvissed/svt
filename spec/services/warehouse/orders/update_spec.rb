require 'rails_helper'

module Warehouse
  module Orders
    RSpec.describe Update, type: :model do
      # let(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
      # let(:order) { create(:order, workplace: workplace, without_items: true) }
      # # let(:item) { create(:used_item, inv_item: order.item_to_orders.first.inv_item) }
      # # let(:operation) { create(:order_operation, item: item, operationable: order) }

      # # let(:order_params) do
      # #   data = Orders::Edit.new(order.warehouse_order_id)
      # #   data.run
      # #   data.data[:order]['item_to_orders_attributes'].each_with_index do |io, index|
      # #     if index.zero?
      # #       io['_destroy'] = 1
      # #     end
      # #
      # #     io.delete('inv_item')
      # #   end
      # #   data.data[:order]['item_to_orders_attributes'].push({ inv_item_id: workplace.items.first.item_id })
      # #
      # #   data.data[:order]
      # # end
      # subject { Update.new(order.warehouse_order_id, order_params) }

      # it 'test' do
      #   puts order.inspect
      #   # puts operation.inspect
      #   # puts order.operations.inspect
      # end

      # context 'when item was destroyed' do
      #   let(:order_params) do
      #     data = Orders::Edit.new(order.warehouse_order_id)
      #     data.run
      #     data.data[:order]['item_to_orders_attributes'].each_with_index do |io, index|
      #       if index.zero?
      #         io['_destroy'] = 1
      #       end

      #       io.delete('inv_item')
      #     end

      #     data.data[:order]
      #   end

      #   it 'destroys record from ItemToOrder model' do
      #     subject.run
      #     expect(ItemToOrder.exists?(warehouse_item_to_order_id: order_params['item_to_orders_attributes'].first['id'])).to be_falsey
      #   end

      #   it 'destroys record from Operation' do
      #     subject.run
      #     expect(Item.find(order_params['item_to_orders_attributes'].first['invent_item_id']).operations.first.status).to eq 'done'
      #   end
      # end


      # it 'adds new items'

    end
  end
end
