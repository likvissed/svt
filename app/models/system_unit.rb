class SystemUnit < ApplicationRecord

  has_many :etalon_details
  has_many :etalon_changes
  has_many :logs

  validates :invnum, uniqueness: true, presence: true

end
