FactoryBot.define do
  factory :binder, class: Binder do
    description { 'Name description' }
    sign_id { Sign.first.sign_id }
    warehouse_item_id { nil }
    invent_item_id { nil }

    after(:build) do |binder|
      binder.invent_item_id = binder.invent_item.item_id if binder.invent_item
      binder.warehouse_item_id = binder.warehouse_item.id if binder.warehouse_item
    end
  end
end
