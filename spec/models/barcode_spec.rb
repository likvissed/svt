
require 'feature_helper'

RSpec.describe Barcode, type: :model do
  it { is_expected.to belong_to(:codeable) }
end
