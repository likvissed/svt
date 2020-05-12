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

    it 'does not change :count_reserved attribute of items' do
      subject.run

      expect(item_1.reload.count_reserved).to eq 1
      expect(item_2.reload.count_reserved).to eq 1
    end

    its(:run) { is_expected.to be_falsey }
  end

  shared_examples 'failed destroy :write_off order' do
    it 'does not destroy inv_item_to_operations' do
      expect { subject.run }.not_to change(InvItemToOperation, :count)
    end

    it 'does not destroy order' do
      expect { subject.run }.not_to change(Order, :count)
    end

    it 'does not destroy operations' do
      expect { subject.run }.not_to change(Operation, :count)
    end

    it 'does not change :count_reserved attribute of items' do
      subject.run

      expect(w_item_1.reload.count_reserved).to eq 1
      expect(w_item_2.reload.count_reserved).to eq 1
    end

    it 'does not change status of inv_items' do
      subject.run

      Invent::Item.find_each { |inv_item| expect(inv_item.status).to eq 'waiting_write_off' }
    end

    it 'does not change status of warehouse_items' do
      subject.run

      Item.find_each { |item| expect(item.status).to eq 'waiting_write_off' }
    end

    its(:run) { is_expected.to be_falsey }
  end

  shared_examples 'destroy location for item' do
    let(:location) { create(:location) }
    let(:warehouse_item_1) { create(:used_item, location: location) }
    context 'item has location' do
      before { item_1.warehouse_item = warehouse_item_1 }

      it 'does destroy location' do
        expect { subject.run }.to change(Location, :count).by(-1)
      end

      it 'update locaion_id for item' do
        subject.run

        expect(warehouse_item_1.reload.location_id).to eq 0
      end
    end
  end
end
