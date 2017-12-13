require 'rails_helper'

module Warehouse
  RSpec.describe ItemToOrder, type: :model do
    it { is_expected.to belong_to(:inv_item).class_name('Invent::Item').with_foreign_key('invent_item_id') }
    it { is_expected.to belong_to(:order) }
  end
end
