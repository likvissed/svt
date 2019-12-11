module Warehouse
  FactoryBot.define do
    factory :warehouse_property_value, class: PropertyValue do
      warehouse_property_value_id { nil }
      warehouse_item_id { nil }
      property_id { nil }
      value { '' }
    end

    factory :mb_property_values, parent: :warehouse_property_value, class: PropertyValue do
      property_id { Invent::Property.find_by(name: :mb).property_id }
      value { 'P5Q_SE2' }
    end

    factory :ram_property_values, parent: :warehouse_property_value, class: PropertyValue do
      property_id { Invent::Property.find_by(name: :ram).property_id }
      value { '3' }
    end

    factory :cpu_property_values, parent: :warehouse_property_value, class: PropertyValue do
      property_id { Invent::Property.find_by(name: :cpu).property_id }
      value { 'Intel(R) Core(TM)2 Quad CPU Q8300 @ 2.50GHz' }
    end

    factory :hdd_property_values, parent: :warehouse_property_value, class: PropertyValue do
      property_id { Invent::Property.find_by(name: :hdd).property_id }
      value { 'WDC WD5000AAKS-00UU3A0' }
    end

    factory :video_property_values, parent: :warehouse_property_value, class: PropertyValue do
      property_id { Invent::Property.find_by(name: :video).property_id }
      value { 'NVIDIA GeForce GTS 250' }
    end
  end
end
