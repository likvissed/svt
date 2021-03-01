
require 'feature_helper'

RSpec.describe Barcode, type: :model do
  it { is_expected.to belong_to(:codeable) }
  it { is_expected.to validate_presence_of(:codeable_type) }

  describe '#uniqueness_type_and_id' do
    let(:item) { create(:item, :with_property_values, type_name: :monitor) }
    subject { item.barcode_item }
    before { subject.id = nil }

    it 'adds :barcode_already_exists error for barcode' do
      subject.valid?

      expect(subject.errors.details[:base]).to include(error: :barcode_already_exists, codeable_id: subject.codeable_id)
    end
  end
end
