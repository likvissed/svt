require 'rails_helper'

module Inventory
  RSpec.describe InvItem, type: :model do

    context "#presence_model" do
      context "when item_type belongs to array InvItem::PRESENCE_MODEL_EXCEPT" do
        InvItem::PRESENCE_MODEL_EXCEPT.each do |type|
          context "when model is set" do
            let(:item) { build(:presence_model_except_item_with_model, inv_type: InvType.find_by(name: type)) }

            it "should be valid" do
              expect(item).to be_valid
            end
          end

          context "when model is not set" do
            let(:item) { build(:presence_model_except_item_without_model, inv_type: InvType.find_by(name: type)) }

            it "should be valid" do
              expect(item).to be_valid
            end
          end
        end
      end

      context "when item_type is not part of array InvItem::PRESENCE_MODEL_EXCEPT." do
        context "when model_id is set" do
          let(:item) { build(:monitor_item_with_model_id) }

          it "should be valid" do
            expect(item).to be_valid
          end
        end

        context "when item_model is set" do
          let(:item) { build(:monitor_item_with_item_model) }

          it "should be valid" do
            expect(item).to be_valid
          end
        end

        context "when model is not set" do
          let(:item) { build(:monitor_item_without_model) }

          it "should not be valid" do
            expect(item).not_to be_valid
          end
        end
      end
    end

    context "#set_default_model" do
      context "when model_id.zero?" do
        let(:item) { create(:monitor_item_with_item_model) }

        it "should set model_id to nil" do
          expect(item.model_id).to be_nil
        end
      end
    end

    context "#check_property_value" do
      # Тестирование check_property_value
    end
  end
end