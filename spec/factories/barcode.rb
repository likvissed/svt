FactoryBot.define do
  factory :barcode_invent_item, class: Barcode do
    codeable_type { 'Invent::Item' }
  end

  factory :barcode_warehouse_item, class: Barcode do
    codeable_type { 'Warehouse::Item' }
  end
end
