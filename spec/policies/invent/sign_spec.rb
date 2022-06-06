require 'spec_helper'

module Invent
  RSpec.describe SignPolicy do
    let(:***REMOVED***_user) { create(:***REMOVED***_user) }
    let(:manager) { create(:***REMOVED***_user) }
    let(:worker) { create(:shatunova_user) }
    let(:read_only) { create(:tyulyakova_user) }
    before do
      allow_any_instance_of(User).to receive(:presence_user_in_users_reference)
      create(:sign)
    end
    subject { SignPolicy }

    permissions :ctrl_access? do
      let(:model) { Sign.first }

      include_examples 'policy for worker'
    end
  end
end
