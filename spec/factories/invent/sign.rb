module Invent
  FactoryBot.define do
    factory :sign, class: Sign do
      name { 'spsi' }
      short_description { 'СПСИ' }
      long_description { 'Спец. проверки' }
    end
  end
end
