module Invent
  module LkInvents
    class BaseService < Invent::ApplicationService
      private

      # Получить список работников указанного отдела.
      def load_users
        data[:users] = UsersReference.info_users("departmentForAccounting==#{@division}").map { |employee| employee.slice('lastName', 'firstName', 'middleName', 'id', 'professionForDocuments', 'fullName') }
      end
    end
  end
end
