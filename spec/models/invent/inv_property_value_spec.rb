require 'rails_helper'

module Invent
  RSpec.describe InvPropertyValue, type: :model do
    it { is_expected.to have_one(:standart_discrepancy).class_name('Standart::Discrepancy').with_foreign_key('property_value_id') }
    it { is_expected.to belong_to(:inv_property).with_foreign_key('property_id') }
    it { is_expected.to belong_to(:inv_item).with_foreign_key('item_id') }
    it { is_expected.to belong_to(:inv_property_list).with_foreign_key('property_list_id') }

    it { is_expected.to validate_presence_of(:property_id) }

    it { is_expected.to validate_numericality_of(:property_id).is_greater_than(0).only_integer.with_message('не указано') }
  end
end
