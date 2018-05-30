module Warehouse
  shared_examples 'order error format' do
    its(:run) { is_expected.to be_falsey }

    it 'raise error before find order' do
      expect(Order).not_to receive(:find)
      subject.run
    end
  end
end
