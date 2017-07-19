require 'rails_helper'

module Standart
  RSpec.describe Log, type: :model do
    it { is_expected.to belong_to(:inv_item).class_name('Invent::InvItem') }
    it { is_expected.to belong_to(:user) }
  end
end
