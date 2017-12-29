require 'rails_helper'

module Warehouse
  RSpec.describe Operation, type: :model do
    it { is_expected.to belong_to(:item).with_foreign_key('warehouse_item_id') }
    it { is_expected.to belong_to(:location).with_foreign_key('warehouse_location_id') }
    it { is_expected.to belong_to(:stockman).class_name('UserIss').with_foreign_key('stockman_id_tn') }
    it { is_expected.to belong_to(:operationable) }
    it { is_expected.to validate_presence_of(:item_type) }
    it { is_expected.to validate_presence_of(:item_model) }
    it { is_expected.to validate_presence_of(:shift) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.not_to validate_presence_of(:stockman_fio) }
    it { is_expected.not_to validate_presence_of(:date) }

    context 'when status is done' do
      subject { build(:order_operation, status: :done) }

      it { is_expected.to validate_presence_of(:stockman_fio) }
      it { is_expected.to validate_presence_of(:date) }
    end

    describe '#set_initial_status' do
      it 'sets :processing status after initialize object' do
        expect(subject.status).to eq 'processing'
      end
    end
  end
end
