module Warehouse
  FactoryBot.define do
    factory :used_item, class: Item do
      warehouse_type { :with_invent_num }
      status { :used }
      count { 1 }
      count_reserved { 0 }
      invent_num_start { 111 }
      invent_num_end { 111 }

      after(:build) do |item, _ev|
        item.item_type = item.inv_type.short_description if item.inv_type
        item.item_model = item.inv_model.item_model if item.inv_model

        # Если не задан тип и модель
        if !item.item_type && !item.item_model && item.warehouse_type.to_s == 'with_invent_num'
          if item.status != 'non_used'
            item.inv_item ||= create(:item, :with_property_values, type_name: 'monitor')
          else
            item.inv_type ||= Invent::Type.find_by(name: :monitor)
            item.inv_model ||= Invent::Type.find_by(name: :monitor).models.first
          end
        end

        if item.inv_item
          item.inv_type ||= item.inv_item.type
          item.inv_model ||= item.inv_item.model
        end

        if item.warehouse_type.to_s == 'without_invent_num' && !item.item_type && !item.item_model
          item.item_type = 'CD'
          item.item_model = 'ASUS'
        end
      end
    end

    factory :new_item, parent: :used_item, class: Item do
      warehouse_type { :with_invent_num }
      status { :non_used }
      inv_item { nil }
    end

    factory :expanded_item, parent: :used_item, class: Item do
      item_model { 'Asus 123H' }
      invent_type_id { Invent::Type.find_by(name: :notebook).type_id }
      item_type { Invent::Type.find_by(name: :notebook).name }
    end

    factory :item_with_property_values, parent: :used_item, class: Item do
      after(:build) do |item|
        item.item_model = 'HP R321'
        item.invent_type_id = Invent::Type.find_by(name: :pc).type_id
        item.item_type = Invent::Type.find_by(name: :pc).name

        item.property_values << build(:mb_property_values, warehouse_item_id: item.id)
        item.property_values << build(:ram_property_values, warehouse_item_id: item.id)
        item.property_values << build(:cpu_property_values, warehouse_item_id: item.id)
        item.property_values << build(:hdd_property_values, warehouse_item_id: item.id)
        item.property_values << build(:video_property_values, warehouse_item_id: item.id)
      end
    end
  end
end
