module Warehouse
  module Requests
    class SaveRecommendationForm < Reform::Form
      property :comment
      property :recommendation_json, validates: { presence: true }
    end
  end
end
