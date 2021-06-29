module Invent
  module LkInvents
    class BaseService < Invent::ApplicationService
      private

      # Получить список работников указанного отдела.
      def load_users
        data[:users] = UsersReference.info_users("departmentForAccounting==#{@division}").map { |employee| employee.slice('fullName', 'id') }
      end
    end
  end
end
