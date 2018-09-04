require 'feature_helper'

module Invent
  module Items
    RSpec.describe Update, type: :model do
      let!(:user) { create(:user) }
      let!(:old_item) { create(:item, :with_property_values, type_name: :monitor) }
      let(:new_item) do
        edit = Edit.new(old_item.item_id)
        edit.run

        data = edit.data[:item]
        data['invent_num'] = 'new_invent_num'
        # data['item_id'] = data['id']
        data['property_values_attributes'].each do |prop_val|
          prop_val['property_list_id'] = 15

          prop_val.delete('property_list')
        end
        data.delete('get_item_model')

        data.as_json
      end
      subject { Items::Update.new(user, old_item.item_id, new_item) }

      context 'with valid item params' do
        its(:run) { is_expected.to be_truthy }

        it 'updates item data' do
          subject.run
          expect(old_item.reload.invent_num).to eq 'new_invent_num'
          expect(old_item.reload.property_values.first.property_list_id).to eq 15
        end

        it 'broadcasts to items' do
          expect(subject).to receive(:broadcast_items)
          subject.run
        end

        it 'broadcasts to workplaces_list' do
          expect(subject).to receive(:broadcast_workplaces_list)
          subject.run
        end
      end

      context 'with invalid item params' do
        its(:run) { is_expected.to be_falsey }
        before { allow_any_instance_of(Item).to receive(:update_attributes).and_return(false) }

        it 'does not update item data' do
          subject.run
          expect(old_item.reload.invent_num).not_to eq 'new_invent_num'
        end

        it 'does not broadcast to items' do
          expect(subject).not_to receive(:broadcast_items)
          subject.run
        end

        it 'does not broadcast to workplaces_list' do
          expect(subject).not_to receive(:broadcast_workplaces_list)
          subject.run
        end
      end
    end
  end
end
