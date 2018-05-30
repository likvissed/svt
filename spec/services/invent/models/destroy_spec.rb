require 'feature_helper'

module Invent
  module Models
    RSpec.describe Destroy, type: :model do
      let!(:model) { create(:model) }
      subject { Destroy.new(model.model_id) }

      its(:run) { is_expected.to be_truthy }

      it 'destroys model' do
        expect { subject.run }.to change(Model, :count).by(-1)
      end

      it 'broadcasts to models' do
        expect(subject).to receive(:broadcast_models)
        subject.run
      end

      context 'when model was not destroyed' do
        before { allow_any_instance_of(Model).to receive(:destroy).and_return(false) }

        its(:run) { is_expected.to be_falsey }
      end
    end
  end
end
