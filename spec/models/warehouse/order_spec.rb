require 'rails_helper'

module Warehouse
  RSpec.describe Order, type: :model do
    it { is_expected.to have_many(:operations).dependent(:destroy) }
    it { is_expected.to have_many(:item_to_orders).dependent(:destroy) }
    it { is_expected.to have_many(:items).through(:item_to_orders).class_name('Invent::Item') }
    it { is_expected.to belong_to(:workplace).class_name('Invent::Workplace') }
    it { is_expected.to belong_to(:creator).class_name('UserIss').with_foreign_key('creator_id_tn') }
    it { is_expected.to belong_to(:consumer).class_name('UserIss').with_foreign_key('consumer_id_tn') }
    it { is_expected.to belong_to(:validator).class_name('UserIss').with_foreign_key('validator_id_tn') }
  end
end
