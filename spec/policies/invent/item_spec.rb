require 'spec_helper'

module Invent
  RSpec.describe ItemPolicy do
    let(:***REMOVED***_user) { create(:***REMOVED***_user) }
    let(:manager) { create(:***REMOVED***_user) }
    let(:worker) { create(:shatunova_user) }
    let(:read_only) { create(:tyulyakova_user) }
    before { create(:used_item) }
    subject { ItemPolicy }

    permissions :ctrl_access? do
      let(:model) { Item.first }

      include_examples 'policy not for ***REMOVED***_user'
    end

    permissions :destroy? do
      let(:model) { Item.first }

      include_examples 'policy for worker'
    end
  end
end
