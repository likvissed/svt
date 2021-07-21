require 'spec_helper'

module Warehouse
  RSpec.describe ItemPolicy do
    let(:***REMOVED***_user) { create(:***REMOVED***_user) }
    let(:manager) { create(:***REMOVED***_user) }
    let(:worker) { create(:shatunova_user) }
    let(:read_only) { create(:tyulyakova_user) }
    before do
      allow_any_instance_of(User).to receive(:presence_user_in_users_reference)
      create(:used_item)
    end
    subject { ItemPolicy }

    permissions :ctrl_access? do
      let(:model) { Item.first }

      include_examples 'policy not for ***REMOVED***_user'
    end

    permissions :destroy? do
      let(:model) { Item.first }

      include_examples 'policy for worker'
    end

    permissions :update? do
      let(:model) { create(:new_item) }

      include_examples 'policy for worker'
      include_examples 'status for item is non_used'
    end

    permissions :edit? do
      let(:model) { create(:new_item) }

      include_examples 'status for item is non_used'
    end

    permissions :create? do
      let(:model) { create(:new_item) }

      include_examples 'policy for worker'
    end
  end
end
