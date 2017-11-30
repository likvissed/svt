require 'rails_helper'

module Standard
  RSpec.describe LogDetail, type: :model do
    it { is_expected.to belong_to(:log) }
    it { is_expected.to belong_to(:property).class_name('Invent::Property').with_foreign_key('property_id') }
  end
end
