require 'feature_helper'

module Invent
  module Items
    RSpec.describe Avaliable, type: :model do
      let!(:items) { create_list(:item, 4, :with_property_values, type_name: 'monitor') }
      let(:type) { Type.find_by(name: :monitor) }
      subject { Avaliable.new(type.type_id) }
      before { subject.run }

      it 'loads all items without without workplace and with specified type' do
        expect(subject.data.count).to eq items.count
      end

      it 'adds :main_info and :full_item_model fields to the each item' do
        expect(subject.data.first).to include(:main_info, 'full_item_model')
      end
    end
  end
end
