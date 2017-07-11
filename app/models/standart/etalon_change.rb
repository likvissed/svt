module Standart
  class EtalonChange < ApplicationRecord
    belongs_to :system_unit
    belongs_to :detail_type

    validates :device, :system_unit, :detail_type, :event, presence: true

    enum event: %w[Добавилось Изменилось Удалилось]
  end
end
