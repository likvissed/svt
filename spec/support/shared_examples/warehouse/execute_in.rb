module Warehouse
  shared_examples 'execute_in specs' do
    its(:run) { is_expected.to be_truthy }

    it 'creates order instance variable' do
      subject.run

      expect(subject.instance_variable_get(:@order)).to eq Order.find(order.id)
    end

    it 'sets stockman attributes to the done operations' do
      subject.run

      operations.first.reload
      expect(operations.first.stockman_id_tn).to eq current_user.id_tn
      expect(operations.first.stockman_fio).to eq current_user.fullname
    end

    it 'changes status of done operation' do
      subject.run

      expect(operations.first.reload.done?).to be_truthy
    end
  end
end
