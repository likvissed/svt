require 'feature_helper'

module Invent
  module Models
    RSpec.describe Destroy, type: :model do
      let!(:model) { create(:model) }
      subject { Destroy.new(model.model_id) }

      it 'destroys model' do
        expect { subject.run }.to change(Model, :count).by(-1)
      end

      it 'broadcasts to models' do
        expect(subject).to receive(:broadcast_models)
        subject.run
      end
    end
  end
end
