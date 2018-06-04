require 'spec_helper'

module Invent
  RSpec.describe ModelPolicy do
    let(:manager) { create(:***REMOVED***_user) }
    let(:worker) { create(:shatunova_user) }
    let(:read_only) { create(:tyulyakova_user) }
    before { create(:model) }
    subject { ModelPolicy }

    permissions :ctrl_access? do
      let(:model) { Model.first }

      include_examples 'policy for worker'
    end
  end
end
