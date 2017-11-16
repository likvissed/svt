require 'rails_helper'

module Warehouse
  RSpec.describe Item, type: :model do
    it { is_expected.to belong_to(:inv_item).class_name('Invent::InvItem').with_foreign_key('invent_item_id') }
    it { is_expected.to belong_to(:inv_type).class_name('Invent::InvType').with_foreign_key('type_id') }
    it { is_expected.to belong_to(:inv_model).class_name('Invent::InvModel').with_foreign_key('model_id') }
  end
end
