module Warehouse
  module Requests
    class SaveRecommendationForm < Reform::Form
      property :comment
      property :status, populator: -> (model:, fragment:, **) do
        self.status = 'send_to_owner'
      end
      property :recommendation_json, validates: { presence: true }
    end
  end
end
