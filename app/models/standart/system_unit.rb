module Standart
  class SystemUnit < ApplicationRecord
    has_many :etalon_details, dependent: :destroy
    has_many :etalon_changes, dependent: :destroy
    has_many :logs

    validates :invnum, uniqueness: true, presence: true
  end
end
