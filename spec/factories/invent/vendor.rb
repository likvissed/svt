module Invent
  FactoryBot.define do
    factory :vendor, class: Vendor do
      sequence(:vendor_name) { |i| "Vendor #{i}" }
    end
  end
end
