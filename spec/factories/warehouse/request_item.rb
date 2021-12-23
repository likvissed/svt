module Warehouse
  FactoryBot.define do
    factory :request_item, class: RequestItem do
      type_name { 'pc' }
      name { 'Системный блок' }
      reason { 'Старый тормозит' }
      invent_num { '765123' }
      count { '1' }
      description { 'Офисный ПК: Intel Core i3, RAM 4Gb, HDD 500Gb,VA встроеный, Монитор  22", клавиатура, мышь, ОС, Офис' }
    end
  end
end
