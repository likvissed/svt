module Warehouse
  shared_examples 'execute_write_off specs' do
    its(:run) { is_expected.to be_truthy }

    it 'sets stockman attributes to the done operations' do
      subject.run

      operations.first.reload
      expect(operations.last.reload.stockman_id_tn).to eq current_user.id_tn
      expect(operations.last.reload.stockman_fio).to eq current_user.fullname
    end

    it 'changes status of done operation' do
      subject.run

      expect(operations.last.reload.done?).to be_truthy
    end
  end

  # shared_examples 'execute_out failed specs' do
  #   its(:run) { is_expected.to be_falsey }

  #   it 'does not change status of operations' do
  #     subject.run

  #     operations.each { |op| expect(op.reload.status).to eq 'processing' }
  #   end

  #   it 'does not change status of inv_items' do
  #     subject.run

  #     inv_items.each { |inv_item| expect(inv_item.reload.status).to eq 'waiting_take' }
  #   end

  #   it 'does not change count of selected items' do
  #     subject.run

  #     [first_item, sec_item].each do |inv_item|
  #       expect(inv_item.reload.count).to eq 1
  #       expect(inv_item.reload.count_reserved).to eq 1
  #     end
  #   end
  # end
end
