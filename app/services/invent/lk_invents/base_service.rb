module Invent
  module LkInvents
    class BaseService < Invent::ApplicationService
      private

      # Получить список работников указанного отдела.
      def load_users
        data[:users] = UserIss.select(:id_tn, :fio).where(dept: @division)
      end
    end
  end
end
