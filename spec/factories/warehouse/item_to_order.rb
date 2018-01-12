module Warehouse
  FactoryBot.define do
    factory :item_to_order, class: ItemToOrder do
      order nil
      inv_item nil
    end
  end
end
