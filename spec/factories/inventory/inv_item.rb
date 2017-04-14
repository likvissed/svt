module Inventory
  FactoryGirl.define do
    factory :item, class: InvItem do
      parent_id     0
      type_id       0
      workplace_id  0
      location      'Location 1'
      model_id      nil
      item_model    nil
      invent_num    '123456'
      serial_num    nil
    end

    # Типы, указанные в массиве InvType::PRESENCE_MODEL_EXCEPT. Например, "Системный блок".
    factory :presence_model_except_item, parent: :item, class: InvItem do
      inv_type    nil
      model_id    nil

      # Модель указана.
      factory :presence_model_except_item_with_model do
        item_model  'Model pc_1'
      end

      # Модель не указана.
      factory :presence_model_except_item_without_model do
        item_model  nil
      end
    end

    # Тип, не указанный в массиве InvType::PRESENCE_MODEL_EXCEPT. Например, "Монитор".
    factory :monitor_item, parent: :item, class: InvItem do
      inv_type    { InvType.find_by(name: 'monitor') }

      # Модель введена вручную
      factory :monitor_item_with_item_model do
        model_id    0
        item_model  'Model monitor_1'
      end

      # Модель выбрана из предложенного списка
      factory :monitor_item_with_model_id do
        model_id    { InvType.find_by(name: 'monitor').inv_models.first.model_id }
        item_model  nil
      end

      # Модель не указана.
      factory :monitor_item_without_model do
        model_id    -1
        item_model  nil
      end
    end

    # Создать фабрику для тестирования метода check_property_value

  end
end