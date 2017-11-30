require 'spec_helper'

module Invent
  module Items
    RSpec.describe Used, type: :model do
      let!(:items) { create_list(:item, 4, :with_property_values, type_name: 'monitor') }
      let(:type) { Type.find_by(name: :monitor) }
      subject { Used.new(type.type_id) }
      before { subject.run }

      it 'loads all items with specified type' do
        expect(subject.data.count).to eq items.count
      end

      it 'adds :main_info and :add_info field to the each item' do
        expect(subject.data.first).to include(:main_info, :add_info)
      end
    end
  end
end
