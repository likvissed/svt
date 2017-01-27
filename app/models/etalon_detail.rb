class EtalonDetail < ApplicationRecord

  belongs_to :system_unit
  belongs_to :detail_type

  validates :device, :system_unit, :detail_type, presence: true

end
