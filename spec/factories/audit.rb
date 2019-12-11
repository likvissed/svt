FactoryBot.define do
  factory :audit, class: Hash do
    cpu { ['intel(r) core(tm) i3-2100 cpu @ 3.10ghz'] }
    ram { [3.5] }
    hdd { ['st500dm002-1bd142 ata device'] }
    mb { ['aquarius pro, std, elt series'] }
    video { ['nvidia geforce gtx 550 ti'] }
    last_connection { [Time.zone.now.to_s] }

    initialize_with { attributes }
  end
end
