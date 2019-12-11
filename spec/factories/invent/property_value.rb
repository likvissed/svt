module Invent
  FactoryBot.define do
    factory :property_value, class: PropertyValue do
      property_list_id { 0 }
      value { '' }
    end
  end
end
