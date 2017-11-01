require 'spec_helper'

module Invent
  module Items
    RSpec.describe Index, type: :model do
      let(:user) { create :user }
      let(:workplace_count) { create :active_workplace_count, users: [user] }
      let!(:workplace) { create :workplace_pk, :add_items, items: %i[pc monitor], workplace_count: workplace_count }
      let(:data_keys) { %i[totalRecords data] }
      let(:params) { { start: 0, length: 25 } }
      subject { Index.new(params) }

      include_examples 'run methods', %w[load_items]

      it 'fills the @data hash with %i[items totalRecords] keys' do
        subject.run
        expect(subject.data.keys).to include *data_keys
      end

      it 'loads all inv_items' do
        subject.run
        expect(subject.data.count).to eq InvItem.count
      end

      it 'adds :model and :description field to each item' do
        subject.run
        expect(subject.data[:data].first).to include('model', 'description')
      end
    end
  end
end
