module Warehouse
  module Requests
    class SendForAnalysisForm < Reform::Form
      property :executor_fio, validates: { presence: true }
      property :executor_tn
      property :comment
      property :status, populator: -> (model:, fragment:, **) do
        self.status = 'analysis'
      end
    end
  end
end
