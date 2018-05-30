module Warehouse
  shared_examples 'destroys order with nested models' do
    its(:run) { is_expected.to be_truthy }

    it 'destroys operations' do
      expect { subject.run }.to change(Operation, :count).by(-2)
    end

    it 'destroys order' do
      expect { subject.run }.to change(Order, :count).by(-1)
    end
  end

  shared_examples 'failed destroy :out order' do
    it 'does not destroy inv_items' do
      expect { subject.run }.not_to change(Invent::Item, :count)
    end

    it 'does not destroy inv_item_to_operations' do
      expect { subject.run }.not_to change(InvItemToOperation, :count)
    end

    it 'does not destroy order' do
      expect { subject.run }.not_to change(Order, :count)
    end

    it 'does not destroy operations' do
      expect { subject.run }.not_to change(Operation, :count)
    end

    it 'does not change :count attribute of items' do
      subject.run
      expect(item_1.reload.count_reserved).to eq 1
      expect(item_2.reload.count_reserved).to eq 1
    end

    its(:run) { is_expected.to be_falsey }
  end
end
