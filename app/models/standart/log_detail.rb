module Standart
  class LogDetail < ApplicationRecord
    belongs_to :log
    belongs_to :detail_type

    validates :log_id, :detail_type_id, presence: true
  end
end
