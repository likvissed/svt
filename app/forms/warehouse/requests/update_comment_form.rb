module Warehouse
  module Requests
    class UpdateCommentForm < Reform::Form
      property :comment
      property :status

      validate :check_status

      def check_status
        errors.add(:base, :request_is_close) if %w[completed reject].include?(status)
      end
    end
  end
end
