class DetailType < ApplicationRecord

  has_many :etalon_details
  has_many :etalon_changes
  has_many :log_details

  validates :type_name, :title, presence: true

end
