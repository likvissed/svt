module Warehouse
  shared_examples 'prepare_to_deliver specs' do
    its(:run) { is_expected.to be_truthy }

    it 'sets :operations_attributes and :selected_op keys to the data variable' do
      subject.run
      expect(subject.data.keys).to include(:operations_attributes, :selected_op)
    end

    it 'loads :inv_items for each operation' do
      subject.run
      subject.data[:operations_attributes].each do |op|
        expect(op).to include('inv_items_attributes')
      end
    end

    it 'loads inv_items objects of selected operations' do
      subject.run
      expect(subject.data[:operations_attributes].last['inv_items_attributes'].first).to include('id', 'property_values', 'short_item_model')
    end
  end
end
