module Warehouse
  shared_examples 'failed updating models' do
    [Item, InvItemToOperation, Operation].each do |klass|
      it "does not create #{klass.name} record" do
        expect { subject.run }.not_to change(klass, :count)
      end
    end

    its(:run) { is_expected.to be_falsey }
  end

  shared_examples 'failed updating on add' do
    include_examples 'failed updating models'

    it 'does not change status of Invent::Item record' do
      subject.run
      expect(Invent::Item.find(new_operation[:inv_item_ids][0]).status).to be_nil
    end
  end

  shared_examples 'failed updating on del' do
    include_examples 'failed updating models'

    it 'does not change status of Invent::Item record' do
      subject.run
      expect(updated_item.status).to eq 'waiting_bring'
    end
  end
end
