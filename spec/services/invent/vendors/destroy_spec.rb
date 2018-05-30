require 'feature_helper'

module Invent
  module Vendors
    RSpec.describe Destroy, type: :model do
      let!(:vendor) { create(:vendor) }
      subject { Destroy.new(vendor.vendor_id) }

      it 'destroys model' do
        expect { subject.run }.to change(Vendor, :count).by(-1)
      end

      it 'broadcasts to models' do
        expect(subject).to receive(:broadcast_vendors)
        subject.run
      end
    end
  end
end
