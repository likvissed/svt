require 'rails_helper'

module Warehouse
  RSpec.describe Operation, type: :model do
    it { is_expected.to belong_to(:item).with_foreign_key('warehouse_item_id') }
    it { is_expected.to belong_to(:location).with_foreign_key('warehouse_location_id') }
    it { is_expected.to belong_to(:stockman).class_name('UserIss').with_foreign_key('stockman_id_tn') }
    it { is_expected.to belong_to(:operationable) }

    describe '#set_initial_status' do
      it 'sets :processing status after initialize object' do
        expect(subject.status).to eq 'processing'
      end
    end
  end
end
