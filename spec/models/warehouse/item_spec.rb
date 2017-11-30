require 'rails_helper'

module Warehouse
  RSpec.describe Item, type: :model do
    it { is_expected.to belong_to(:item).class_name('Invent::Item').with_foreign_key('invent_item_id') }
    it { is_expected.to belong_to(:type).class_name('Invent::Type') }
    it { is_expected.to belong_to(:model).class_name('Invent::Model') }
  end
end
