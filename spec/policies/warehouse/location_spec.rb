require 'spec_helper'

module Warehouse
  RSpec.describe LocationPolicy do
    let(:***REMOVED***_user) { create(:***REMOVED***_user) }
    let(:manager) { create(:***REMOVED***_user) }
    let(:worker) { create(:shatunova_user) }
    let(:read_only) { create(:tyulyakova_user) }
    before { create(:used_item) }
    subject { LocationPolicy }

    permissions :ctrl_access? do
      let(:model) { Item.first }

      include_examples 'policy not for ***REMOVED***_user'
    end
  end
end
