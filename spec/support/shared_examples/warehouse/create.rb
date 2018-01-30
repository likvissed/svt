module Warehouse
  shared_examples 'failed creating models' do
    [Order, Item, ItemToOrder, Operation].each do |klass|
      it "does not create #{klass.name} record" do
        expect { subject.run }.not_to change(klass, :count)
      end
    end

    its(:run) { is_expected.to be_falsey }
  end

  shared_examples 'failed creating' do
    include_examples 'failed creating models'

    it 'does not change status of Invent::Item model' do
      subject.run
      Invent::Item.where(item_id: invent_item_ids).each { |item| expect(item.status).to be_nil }
    end
  end
end
