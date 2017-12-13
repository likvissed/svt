require 'rails_helper'

module Warehouse
  RSpec.describe Order, type: :model do
    it { is_expected.to have_many(:operations).dependent(:destroy) }
    it { is_expected.to have_many(:item_to_orders).dependent(:destroy) }
    it { is_expected.to have_many(:inv_items).through(:item_to_orders).class_name('Invent::Item') }
    it { is_expected.to belong_to(:workplace).class_name('Invent::Workplace') }
    it { is_expected.to belong_to(:creator).class_name('UserIss').with_foreign_key('creator_id_tn') }
    it { is_expected.to belong_to(:consumer).class_name('UserIss').with_foreign_key('consumer_id_tn') }
    it { is_expected.to belong_to(:validator).class_name('UserIss').with_foreign_key('validator_id_tn') }
    it { is_expected.to validate_presence_of(:consumer_dept) }
    it { is_expected.to validate_presence_of(:consumer) }
    it { is_expected.to accept_nested_attributes_for(:operations).allow_destroy(true) }
    it { is_expected.to accept_nested_attributes_for(:item_to_orders).allow_destroy(true) }

    describe '#uniqueness_of_workplace' do
      let!(:workplace_1) { create(:workplace_pk, :add_items, items: [:pc, :monitor], dept: ***REMOVED***) }
      let!(:workplace_2) { create(:workplace_pk, :add_items, items: [:pc, :monitor]) }
      before { subject.valid? }

      context 'when items belongs to the different workplaces' do
        let(:item_to_orders) do
          [
            { invent_item_id: workplace_1.items.first.item_id },
            { invent_item_id: workplace_2.items.first.item_id }
          ]
        end
        subject { build(:order, :without_items, item_to_orders_attributes: item_to_orders) }

        it 'adds :uniq_workplace error' do
          expect(subject.errors.details[:base]).to include(error: :uniq_workplace)
        end
        
        it { is_expected.not_to be_valid }
      end

      context 'when items belongs to the one workplace' do
        subject { build(:order) }

        it { is_expected.to be_valid }
      end
    end

    describe '#set_initial_status' do
      it 'sets :processing status after initialize object' do
        expect(subject.status).to eq 'processing'
      end
    end

    describe '#set_workplace' do
      let!(:workplace) { create(:workplace_pk, :add_items, items: [:pc, :monitor], dept: ***REMOVED***) }
      let(:item_to_orders) do
        [
          { invent_item_id: workplace.items.first.item_id },
          { invent_item_id: workplace.items.last.item_id }
        ]
      end
      subject { build(:order, :without_items, item_to_orders_attributes: item_to_orders) }

      it 'sets :workplace references after validate object' do
        expect { subject.valid? }.to change(subject, :workplace_id).to(workplace.workplace_id)
      end
    end

    describe '#set_creator' do
      let(:user) { create(:user) }
      before { subject.set_creator(user) }

      it 'sets creator_id_tn' do
        expect(subject.creator_id_tn).to eq user.id_tn
      end

      it 'sets creator_fio' do
        expect(subject.creator_fio).to eq user.fullname
      end
    end

    describe '#at_least_one_inv_item' do
      subject { build(:order, :without_items) }

      it 'adds :at_least_one_inv_item error if item_to_orders is empty' do
        subject.valid?
        expect(subject.errors.details[:base]).to include(error: :at_least_one_inv_item)
      end
    end
  end
end
