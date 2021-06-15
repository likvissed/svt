require 'feature_helper'

module Warehouse
  RSpec.describe AttachmentOrder, type: :model do
    it { is_expected.to belong_to(:order).with_foreign_key('order_id').inverse_of(:attachment) }
  end

  describe '#presence_order' do
    subject { build(:attachment_order, order: order) }

    context 'when order was delete' do
      let(:order) { create(:order) }
      let!(:user) { create(:user) }
      before { Orders::Destroy.new(user, order.id).run }

      it 'adds error :warehouse_order_is_not_out_or_done' do
        subject.valid?

        expect(subject.errors.details[:base]).to include(error: :warehouse_order_is_not_present, order_id: order.id)
      end
    end

    context 'when status order is :done and operation not :out' do
      let!(:order) do
        order = build(:order)
        order.operation = :in
        order.status = :done
        order.save(validate: false)
        order
      end

      it 'adds error :warehouse_order_is_not_out_or_done' do
        subject.valid?

        expect(subject.errors.details[:base]).to include(error: :warehouse_order_is_not_out_or_done)
      end
    end

    context 'when operation order is :out and status not :done' do
      let!(:order) do
        order = build(:order)
        order.operation = :out
        order.status = :processing
        order.save(validate: false)
        order
      end

      it 'adds error :warehouse_order_is_not_out_or_done' do
        subject.valid?

        expect(subject.errors.details[:base]).to include(error: :warehouse_order_is_not_out_or_done)
      end
    end

    context 'when order already have attachment' do
      let!(:order) do
        order = build(:order)
        order.operation = :out
        order.status = :done
        order.save(validate: false)
        order
      end
      let(:att_order) { create(:attachment_order, order: order) }
      before { order.attachment = att_order }
      subject { att_order }

      it 'adds error :warehouse_order_is_present_attachment' do
        subject.valid?

        expect(subject.errors.details[:base]).to include(error: :warehouse_order_is_present_attachment, order_id: order.id)
      end
    end

    context 'when attachment order is valid' do
      let!(:order) do
        order = build(:order)
        order.operation = :out
        order.status = :done
        order.save(validate: false)
        order
      end
      let(:att_order) { build(:attachment_order, order: order) }
      subject { att_order }

      it { is_expected.to be_valid }

      context 'when file adds in order' do
        let!(:att_order) { create(:attachment_order, order: order) }

        it 'attachment belong to order' do
          expect(order.reload.attachment.order_id).to eq order.id
          expect(order.reload.attachment.document.identifier).to eq att_order.document.filename
        end
      end
    end
  end
end
