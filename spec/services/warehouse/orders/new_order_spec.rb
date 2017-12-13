require 'spec_helper'

module Warehouse
  module Orders
    RSpec.describe NewOrder, type: :model do
      let(:user) { create(:user) }
      let(:workplace_count) { create(:active_workplace_count, users: [user]) }
      subject { NewOrder.new(:in) }
      before { subject.run }

      it 'fills the @data with %w[order operation divisioins] keys' do
        expect(subject.data).to include(:order, :eq_types, :divisions)
      end

      it 'loads all divisions to the :divisions key' do
        expect(subject.data[:divisions].length).to eq Invent::WorkplaceCount.count
      end

      it 'creates instance of Order' do
        expect(subject.data[:order]).to be_instance_of(Order)
      end

      it 'loads all types of equipment' do
        expect(subject.data[:eq_types].count).to eq Invent::Type.count - 1
      end
    end
  end
end
