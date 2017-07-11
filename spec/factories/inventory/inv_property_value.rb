module Inventory
  FactoryGirl.define do
    factory :property_value, class: InvPropertyValue do
      property_list_id 0
      value ''
    end
  end
end
