module Invent
  FactoryBot.define do
    factory :model, class: Model do
      vendor { Vendor.find_by(vendor_name: 'Acer') }
      type { Type.find_by(name: :printer) }
      item_model 'New model'
    end
  end
end
