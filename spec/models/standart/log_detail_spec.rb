require 'rails_helper'

module Standart
  RSpec.describe LogDetail, type: :model do
    it { is_expected.to belong_to(:log) }
    it { is_expected.to belong_to(:inv_property).class_name('Invent::InvProperty').with_foreign_key('property_id') }
  end
end
