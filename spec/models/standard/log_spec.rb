require 'rails_helper'

module Standard
  RSpec.describe Log, type: :model do
    it { is_expected.to belong_to(:item).class_name('Invent::Item') }
  end
end
