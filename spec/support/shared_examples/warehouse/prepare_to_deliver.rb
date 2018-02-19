module Warehouse
  shared_examples 'prepare_to_deliver specs' do
    its(:run) { is_expected.to be_truthy }

    it 'sets :inv_item_ids and :inv_items_attributes keys to the data variable' do
      subject.run
      expect(subject.data.keys).to include(:inv_items_attributes, :selected_op)
    end

    it 'loads inv_items objects of selected operations' do
      subject.run
      expect(subject.data[:inv_items_attributes].last).to include('id', 'property_values', 'get_item_model')
    end

    let(:expected_selected_op) do
      {
        warehouse_operation_id: order.operations.first.warehouse_operation_id,
        invent_item_id: first_inv_item.item_id
      }
    end

    it 'loads invent_item_id of selected operations' do
      subject.run
      expect(subject.data[:selected_op].first).to eq expected_selected_op.as_json
    end
  end
end
