require 'spec_helper'

module Invent
  module Items
    RSpec.describe Busy, type: :model do
      let!(:workplaces) { create_list(:workplace_pk, 2, :add_items, items: %i[pc monitor monitor]) }
      let!(:items) { create_list(:item, 4, :with_property_values, type_name: 'monitor') }
      let(:type) { Type.find_by(name: :pc) }
      subject { Busy.new(type.type_id) }
      before { subject.run }

      context 'with invent_num' do
        subject { Busy.new(type.type_id, workplaces.first.items.first.invent_num) }

        it 'loads items with specified type and invent_num' do
          expect(subject.data.count).to eq 1
        end
      end

      it 'loads all items with specified type' do
        expect(subject.data.count).to eq Item.where(type: type).count
      end

      it 'adds :main_info and :add_info field to the each item' do
        expect(subject.data.first).to include(:main_info, :add_info)
      end
    end
  end
end
