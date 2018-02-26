module Warehouse
  FactoryBot.define do
    factory :inv_item_to_operation, class: InvItemToOperation do
      inv_item nil
      operation nil
    end
  end
end
