require 'spec_helper'

module Warehouse
  RSpec.describe SupplyPolicy do
    let(:manager) { create(:***REMOVED***_user) }
    let(:worker) { create(:shatunova_user) }
    let(:read_only) { create(:tyulyakova_user) }
    before { create(:supply) }
    subject { SupplyPolicy }

    permissions :new? do
      let(:model) { Supply.first }

      include_examples 'policy for worker'
    end

    permissions :create? do
      let(:model) { Supply.first }

      include_examples 'policy for worker'
    end

    permissions :edit? do
      let(:model) { Supply.first }

      include_examples 'policy for worker'
    end

    permissions :update? do
      let(:model) { Supply.first }

      include_examples 'policy for worker'
    end

    permissions :destroy? do
      let(:model) { Supply.first }

      include_examples 'policy for worker'
    end
  end
end
