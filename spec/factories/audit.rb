FactoryBot.define do
  factory :audit_processed, class: Hash do
    cpu { ['Intel(R) Core(TM) i5-6400 CPU @ 2.70GHz'] }
    ram { [8] }
    hdd { ['TOSHIB DT01ACA050 SCSI Disk Device'] }
    mb { ['System Product Name'] }
    video { ['Intel(R) HD Graphics 530'] }

    initialize_with { attributes.stringify_keys }
  end

  factory :audit, class: Hash do
    cpu { 'Intel(R) Core(TM) i5-6400 CPU @ 2.70GHz' }
    ram { 8063 }
    hdd { ' TOSHIB  DT01ACA050 SCSI Disk Device' }
    mb { 'System Product Name' }
    video { ' Intel(R) HD Graphics 530' }
    printers { ' HP LaserJet Pro MFP M426f-M427f PCL 6' }

    initialize_with { attributes.stringify_keys }
  end
end
