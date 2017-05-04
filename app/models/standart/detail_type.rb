module Standart
  class DetailType < ApplicationRecord
    has_many :etalon_details, dependent: :restrict_with_error
    has_many :etalon_changes, dependent: :restrict_with_error
    has_many :log_details, dependent: :restrict_with_error

    validates :type_name, :title, presence: true
  end
end
