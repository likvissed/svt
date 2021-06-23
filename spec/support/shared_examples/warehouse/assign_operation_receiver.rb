module Warehouse
  shared_examples 'assigned warehouse_receiver_fio' do
    its(:run) { is_expected.to be_truthy }

    it 'changed warehouse_receiver_fio for operation_one' do
      subject.run

      expect(operation_one.reload.warehouse_receiver_fio).to eq receiver_fio
      expect(operation_two.reload.warehouse_receiver_fio).to be_nil
    end
  end
end
