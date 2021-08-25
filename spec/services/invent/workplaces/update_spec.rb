require 'feature_helper'

module Invent
  module Workplaces
    RSpec.describe Update, type: :model do
      before { allow(Invent::ChangeOwnerWpWorker).to receive(:perform_async).and_return(true) }
      skip_users_reference

      let(:employee) { [build(:emp_***REMOVED***)] }
      let!(:user) { create(:user) }
      let!(:old_workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
      let(:workplace_attachments) { [] }

      context 'with valid workplace params' do
        let(:room) { IssReferenceSite.first.iss_reference_buildings.first.iss_reference_rooms.last }
        let(:new_workplace) do
          update_workplace_attributes(true, user, old_workplace.workplace_id, location_room_id: room.room_id, employee: employee)
        end
        subject { Update.new(user, old_workplace.workplace_id, new_workplace, workplace_attachments) }

        it 'creates a @workplace variable' do
          subject.run
          expect(subject.instance_variable_get(:@workplace)).to eq old_workplace
        end

        it 'sets location_room_id variable' do
          subject.run
          expect(subject.instance_variable_get(:@workplace_params)['location_room_id']).to eq room.room_id
        end

        it 'changes workplace attributes' do
          subject.run
          old_workplace.reload
          expect(old_workplace.iss_reference_room).to eq room
          expect(old_workplace.id_tn).to eq employee.first['id']
        end

        it 'changes items count' do
          expect { subject.run }.to change(old_workplace.reload.items, :count).by(new_workplace['items_attributes'].count - old_workplace.items.count)
        end

        it 'fills the @data at least with %w[short_description fio duty location status] keys' do
          subject.run
          expect(subject.data).to include('short_description', 'fio', 'duty', 'location', 'status')
        end

        it 'broadcasts to items' do
          expect(subject).to receive(:broadcast_items)
          subject.run
        end

        it 'broadcasts to workplaces' do
          expect(subject).to receive(:broadcast_workplaces)
          subject.run
        end

        it 'broadcasts to workplaces_list' do
          expect(subject).to receive(:broadcast_workplaces_list)
          subject.run
        end

        it 'broadcasts to archive_orders' do
          expect(subject).not_to receive(:broadcast_archive_orders)
          subject.run
        end

        context 'and when have item with properties assign barcode' do
          before do
            new_workplace['items_attributes'].push(new_item)
            new_workplace['disabled_filters'] = true
          end

          include_examples 'property_value is creating'
        end

        it 'count barcode increased' do
          subject.run

          expect(Barcode.count).to eq new_workplace['items_attributes'].count
        end

        context 'when workplace have attachments' do
          let(:new_attachment) { { id: nil, workplace_id: nil } }
          let(:file) do
            Rack::Test::UploadedFile.new(Rails.root.join('spec/files/new_pc_config.txt'), 'text/plain')
          end
          let(:present_attachment) { create(:attachment, workplace: old_workplace) }
          let(:workplace_attachments) { [file] }
          before { new_workplace['attachments_attributes'] = [present_attachment.as_json, new_attachment] }

          it 'count of attachments has changed' do
            expect { subject.run }.to change(Attachment, :count).by(workplace_attachments.count)
          end

          context 'and when deletes present ands add new attachment' do
            before do
              new_workplace['attachments_attributes'].each do |att|
                att['_destroy'] = 1 if att['id'].present?
              end
            end

            it 'count attachment not changes' do
              expect { subject.run }.not_to change(Attachment, :count)
            end

            it 'assigns identifier for new file' do
              subject.run

              expect(old_workplace.attachments.first.document.file.identifier).to eq file.original_filename
            end
          end
        end

        context 'when wp have order is processing and updates property_values for item' do
          let(:inv_item) { old_workplace.items.first }
          let(:w_item) { create(:used_item, count_reserved: 1, inv_item: inv_item, status: :waiting_write_off) }
          let(:operation) { build(:order_operation, item: w_item, inv_item_ids: [inv_item.item_id], shift: 1) }
          let!(:order) { create(:order, inv_workplace: old_workplace, operations: [operation]) }

          let(:new_value) { 'New str value' }
          before do
            new_workplace['items_attributes'].first['property_values_attributes'].each do |prop_val|
              prop_val['value'] = new_value
            end
          end

          it 'updates item_model in operation' do
            subject.run

            expect(operation.reload.item_model).to eq inv_item.reload.full_item_model
          end
        end

        its(:run) { is_expected.to be_truthy }
      end

      context 'when add item from another workplace' do
        before do
          allow_any_instance_of(Warehouse::Order).to receive(:set_consumer)
          allow_any_instance_of(Warehouse::Order).to receive(:find_employee_by_workplace).and_return([employee])
        end
        let(:employee) { [build(:emp_***REMOVED***)] }
        let!(:workplace_2) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
        let(:room) { IssReferenceSite.first.iss_reference_buildings.first.iss_reference_rooms.last }
        let(:new_workplace) do
          wp = Invent::LkInvents::EditWorkplace.new(user, old_workplace.workplace_id)
          wp.run

          wp.data['location_room_id'] = room.room_id
          wp.data['id_tn'] = employee.first['id']

          new_mon = workplace_2.items.last.as_json(include: :property_values)
          new_mon['status'] = 'prepared_to_swap'
          new_mon['id'] = new_mon['item_id']
          new_mon['property_values_attributes'] = new_mon['property_values']
          new_mon['barcode_item_attributes'] = new_mon['barcode_item']
          new_mon['property_values_attributes'].each do |prop_val|
            prop_val['id'] = prop_val['property_value_id']

            prop_val.delete('property_value_id')
          end

          new_mon.delete('item_id')
          new_mon.delete('property_values')
          new_mon.delete('barcode_item')

          wp.data.delete('location_room')
          wp.data.delete('new_attachment')
          wp.data['items_attributes'] << new_mon
          wp.data
        end
        let(:swap) { Warehouse::Orders::Swap.new(user, old_workplace.workplace_id, [new_workplace['items_attributes'].last['id']]) }
        subject { Update.new(user, old_workplace.workplace_id, new_workplace, workplace_attachments) }

        it 'runs Warehouse::Orders::Swap service' do
          expect(Warehouse::Orders::Swap).to receive(:new).with(user, old_workplace.workplace_id, [new_workplace['items_attributes'].last['id']]).and_return(swap)
          expect(swap).to receive(:run)
          subject.run
        end

        it 'increases count of items for current workplace' do
          expect { subject.run }.to change(old_workplace.reload.items, :count).by(1)
        end

        it 'reduces count of items for workplace_2' do
          expect { subject.run }.to change(workplace_2.reload.items, :count).by(-1)
        end

        it 'broadcasts to archive_orders' do
          expect(subject).to receive(:broadcast_archive_orders)
          subject.run
        end

        context 'when Warehouse::Orders::Swap service returns false' do
          before { allow_any_instance_of(Warehouse::Orders::Swap).to receive(:run).and_return(false) }

          its(:run) { is_expected.to be_falsey }

          it 'does not update workplace' do
            subject.run
            old_workplace.reload
            expect(old_workplace.iss_reference_room).not_to eq room
            expect(old_workplace.id_tn).not_to eq employee.first['id']
          end
        end
      end

      context 'with invalid workplace params' do
        let(:new_workplace) do
          update_workplace_attributes(false, user, old_workplace.workplace_id)
        end
        subject { Update.new(user, old_workplace.workplace_id, new_workplace, workplace_attachments) }

        its(:run) { is_expected.to be_falsey }
      end
    end
  end
end
