require 'feature_helper'

module Warehouse
  module Orders
    RSpec.describe CreateByInvItem, type: :model do
      let!(:current_user) { create(:user) }
      let!(:workplace) { create(:workplace_pk, :add_items, items: %i[pc monitor]) }
      let(:item) { workplace.items.first }
      subject { CreateByInvItem.new(current_user, item) }

      its(:run) { is_expected.to be_truthy }

      it 'creates warehouse_operation records' do
        expect { subject.run }.to change(Operation, :count).by(1)
      end

      it 'creates warehouse_item_to_orders records' do
        expect { subject.run }.to change(InvItemToOperation, :count).by(1)
      end

      it 'sets :done to the operation attribute' do
        subject.run

        Order.all.includes(:operations).each do |o|
          o.operations.each do |op|
            expect(op.status).to eq 'done'
          end
        end
      end

      it 'sets stockman to the each operation' do
        subject.run

        Order.all.includes(:operations).each do |o|
          o.operations.each do |op|
            expect(op.stockman_id_tn).to eq current_user.id_tn
            expect(op.stockman_fio).to eq current_user.fullname
          end
        end
      end

      it 'sets :done to the order status' do
        subject.run

        Order.all.each { |o| expect(o.done?).to be_truthy }
      end

      it 'creates items' do
        expect { subject.run }.to change(Item, :count).by(1)
      end

      it 'sets count of items to 1' do
        subject.run

        Order.all.includes(operations: :item).each do |o|
          o.operations.each do |op|
            expect(op.item.count).to eq 1
          end
        end
      end

      it 'sets count_reserved of items to 0' do
        subject.run

        Order.all.includes(operations: :item).each do |o|
          o.operations.each do |op|
            expect(op.item.count_reserved).to eq 0
          end
        end
      end

      it 'sets nil to workplace_id attribute of ivnent_item' do
        subject.run

        Order.all.includes(:inv_items).each do |o|
          o.inv_items.each { |i| expect(i.workplace).to be_nil }
        end
      end

      it 'sets a :in_workplace status to each inv_item' do
        subject.run

        Order.all.includes(:inv_items).each do |o|
          o.inv_items.each { |i| expect(i.status).to eq 'in_stock' }
        end
      end

      it 'broadcasts to items' do
        expect(subject).to receive(:broadcast_items)
        subject.run
      end

      it 'broadcasts to archive_orders' do
        expect(subject).to receive(:broadcast_archive_orders)
        subject.run
      end
    end
  end
end
