require 'feature_helper'

module Warehouse
  module Supplies
    RSpec.describe NewSupply, type: :model do
      let(:user) { create(:user) }
      subject { NewSupply.new(user) }
      before { subject.run }

      it 'creates instance of Order' do
        expect(subject.data[:supply]).to be_instance_of(Supply)
      end

      it 'create instance of :in operation' do
        expect(subject.data[:operation]).to be_instance_of(Operation)
      end

      it 'sets 0 to the :shift attribute' do
        expect(subject.data[:operation].shift).to be_zero
      end

      it 'loads all types of equipment' do
        expect(subject.data[:eq_types].count).to eq Invent::Type.count
      end
    end
  end
end
