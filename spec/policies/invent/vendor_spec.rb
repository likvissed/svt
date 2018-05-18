require 'spec_helper'

module Invent
  RSpec.describe VendorPolicy do
    let(:manager) { create(:***REMOVED***_user) }
    subject { VendorPolicy }

    permissions :index? do
      context 'with :manager role' do
        let!(:vendor) { create(:vendor) }

        it 'grants access to the model' do
          expect(subject).to permit(manager, Model.first)
        end
      end
    end
  end
end
