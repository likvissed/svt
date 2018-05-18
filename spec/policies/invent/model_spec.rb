require 'spec_helper'

module Invent
  RSpec.describe ModelPolicy do
    let(:manager) { create(:***REMOVED***_user) }
    subject { ModelPolicy }

    permissions :index? do
      context 'with :manager role' do
        let!(:model) { create(:model) }

        it 'grants access to the model' do
          expect(subject).to permit(manager, Model.first)
        end
      end
    end
  end
end
