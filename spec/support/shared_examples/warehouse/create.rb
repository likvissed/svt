module Warehouse
  shared_examples 'failed creating :in models' do
    [Order, Item, ItemToOrder, Operation].each do |klass|
      it "does not create #{klass.name} record" do
        expect { subject.run }.not_to change(klass, :count)
      end
    end

    its(:run) { is_expected.to be_falsey }
  end

  shared_examples 'failed creating :in' do
    include_examples 'failed creating :in models'

    it 'does not change status of Invent::Item model' do
      subject.run
      Invent::Item.where(item_id: invent_item_ids).each { |item| expect(item.status).to be_nil }
    end
  end

  shared_examples 'failed creating :out models' do
    [Invent::Item, Order, Item, ItemToOrder, Operation].each do |klass|
      it "does not create #{klass.name} record" do
        expect { subject.run }.not_to change(klass, :count)
      end
    end

    its(:run) { is_expected.to be_falsey }
  end

  shared_examples 'failed creating :out' do
    include_examples 'failed creating :out models'

    it 'does not change status and workpalce_id of Invent::Item model' do
      subject.run

      Invent::Item.find_each do |item|
        expect(item.status).to be_nil
        expect(item.workplace_id).to be_nil
      end
    end

    it 'does not changes :count_reserved of selected items' do
      subject.run

      Item.find_each { |item| expect(item.count_reserved).to be_zero }
    end
  end

  shared_examples 'specs for failed on create :out order' do
    context 'when invent_item was not updated' do
      before { allow_any_instance_of(Invent::Item).to receive(:update!).and_raise(ActiveRecord::RecordNotSaved) }

      include_examples 'failed creating :out models'
    end

    context 'and when invent_item did not pass validations' do
      before { allow_any_instance_of(Invent::Item).to receive(:update!).and_raise(ActiveRecord::RecordInvalid) }

      include_examples 'failed creating :out models'
    end

    context 'when item did not save' do
      # before { allow_any_instance_of(Item).to receive(:save!).and_raise(ActiveRecord::RecordNotSaved) }
      before { allow_any_instance_of(Item).to receive(:save).and_return(false) }

      include_examples 'failed creating :out models'
    end

    # context 'when item did not pass validations' do
    #   before { allow_any_instance_of(Item).to receive(:save!).and_raise(ActiveRecord::RecordInvalid) }

    #   include_examples 'failed creating :out models'
    # end
  end
end
