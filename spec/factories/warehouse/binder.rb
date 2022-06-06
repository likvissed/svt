module Warehouse
  FactoryBot.define do
    factory :binder, class: Binder do
      description { 'Name description' }
      sign_id { Invent::Sign.first.sign_id }
      warehouse_item_id { item.id }
    end
  end
end
