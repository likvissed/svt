require 'feature_helper'

module Invent
  module Vendors
    RSpec.describe Create, type: :model do
      let(:vendor_params) { attributes_for(:vendor) }
      subject { Create.new(vendor_params.as_json) }

      its(:run) { is_expected.to be_truthy }

      it 'creates vendor' do
        expect { subject.run }.to change(Vendor, :count).by(1)
      end
    end
  end
end
