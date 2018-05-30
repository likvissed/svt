require 'spec_helper'

module Invent
  RSpec.describe VendorPolicy do
    let(:manager) { create(:***REMOVED***_user) }
    let(:worker) { create(:shatunova_user) }
    let(:read_only) { create(:tyulyakova_user) }
    before { create(:vendor) }
    subject { VendorPolicy }

    permissions :index? do
      let(:model) { Vendor.first }

      include_examples 'policy for worker'
    end
  end
end
