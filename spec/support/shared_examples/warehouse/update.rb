module Warehouse
  shared_examples 'updating order' do
    its(:run) { is_expected.to be_truthy }

    it 'changes :creator attributes (sets :new_user data)' do
      subject.run

      expect(order.reload.creator_id_tn).to eq new_user.id_tn
      expect(order.reload.creator_fio).to eq new_user.fullname
    end
  end

  # =============================================================================

  shared_examples 'updating :in order' do
    include_examples 'updating order'
  end

  shared_examples 'failed updating :in order' do
    its(:run) { is_expected.to be_falsey }

    [Item, InvItemToOperation, Operation].each do |klass|
      it "does not create #{klass.name} record" do
        expect { subject.run }.not_to change(klass, :count)
      end
    end
  end

  shared_examples 'failed updating :in on add' do
    include_examples 'failed updating :in order'

    it 'does not change status of Invent::Item record' do
      subject.run

      expect(Invent::Item.find(new_operation[:inv_item_ids][0]).status).to be_nil
    end
  end

  shared_examples 'failed updating on del' do
    include_examples 'failed updating :in order'

    it 'does not change status of Invent::Item record' do
      subject.run

      expect(updated_item.status).to eq 'waiting_bring'
    end
  end

  # =============================================================================

  shared_examples 'updating :out order' do
    include_examples 'updating order'
  end

  shared_examples 'failed updating :out' do
    # Внесены текущие изменения из-за того, что необходимо при вызове subject.run выполнить метод set_consumer
    # и присвоить consumer_fio и consumer_id_tn. Метод работает, но UsersReference не должен в тестах выполняться
    let(:assign_order) do
      emp_user = build(:emp_***REMOVED***)
      assign_order = order
      assign_order['consumer_fio'] = emp_user.try(:[], 'fullName')
      assign_order['consumer_id_tn'] = emp_user.try(:[], 'id')
      assign_order
    end
    # its(:run) { is_expected.to be_falsey }

    it 'does not change :creator attributes' do
      allow(subject).to receive(:run).and_return(assign_order)
      # subject.run

      expect(order.reload.creator_id_tn).to eq user.id_tn
      expect(order.reload.creator_fio).to eq user.fullname
    end
  end

  shared_examples 'failed updating :out with_invent_num' do
    include_examples 'failed updating :out'

    # [Invent::Item, InvItemToOperation, Operation].each do |klass|
    #   it "does not create #{klass.name} record" do
    #     expect { subject.run }.not_to change(klass, :count)
    #   end
    # end
  end

  shared_examples 'failed updating :out without_invent_num' do
    include_examples 'failed updating :out'

    it 'does not change :count_reserved attribute of new operation' do
      subject.run

      expect(flash_items.reload.count_reserved).to be_zero
    end
  end

  shared_examples 'failed updating :out on add' do
    include_examples 'failed updating :out with_invent_num'

    it 'does not change :count_reserved attribute of new operation' do
      subject.run

      expect(printer_items.reload.count_reserved).to be_zero
    end
  end

  shared_examples 'failed updating :out on del' do
    include_examples 'failed updating :out with_invent_num'

    it 'does not change :count_reserved attribute of removed operation' do
      subject.run

      expect(pc_items.reload.count_reserved).to eq 2
    end
  end

  # =============================================================================

  shared_examples 'updating :write_off order' do
    include_examples 'updating order'
  end

  shared_examples 'failed updating :write_off order' do
    its(:run) { is_expected.to be_falsey }

    [InvItemToOperation, Operation].each do |klass|
      it "does not create #{klass.name} record" do
        expect { subject.run }.not_to change(klass, :count)
      end
    end
  end

  shared_examples 'failed updating :writeOff on del' do
    include_examples 'failed updating :write_off order'

    it 'does not change statuses of items' do
      subject.run

      expect(removed_w_item.reload.status).to eq 'waiting_write_off'
      expect(removed_i_item.reload.status).to eq 'waiting_write_off'
    end

    it 'does not change :count_reserved attribute of items' do
      subject.run

      expect(removed_w_item.reload.count_reserved).to eq 1
    end
  end
end
