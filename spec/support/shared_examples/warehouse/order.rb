module Warehouse
  shared_examples ':cannot_update_done_order error' do
    it 'adds :cannot_update_done_operation' do
      subject.save
      expect(subject.errors.details[:base]).to include(error: :cannot_update_done_order)
    end
  end

  shared_examples 'does not destroy' do
    it 'does not destroy order' do
      expect { order.destroy }.not_to change(Order, :count)
    end

    it 'does not destroy operations' do
      expect { order.destroy }.not_to change(Operation, :count)
    end
  end

  shared_examples 'does not pass verification presence_of(:invent_num) of operation :in' do
    before { subject.operation = 'in' }

    it { is_expected.to_not validate_presence_of(:invent_num) }
  end
end
