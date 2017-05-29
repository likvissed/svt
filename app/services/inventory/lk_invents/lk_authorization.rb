module Inventory
  module LkInvents
    # Класс проверяет запись по указанному sid в таблице user_session. Это необходимо, чтобы убедиться, что
    # пользователь действительно авторизован в ЛК
    class LkAuthorization < BaseService
      include ActiveModel::Validations

      attr_reader :user_session, :***REMOVED***_user_tn

      # sid - SID пользователя в ЛК
      def initialize(sid)
        @***REMOVED***_user_tn = 999_999
        @sid = sid
      end

      def run
        @user_session = UserSession.find(@sid)
        check_timeout
        true
      rescue ActiveRecord::RecordNotFound
        errors.add(:base, :access_denied)
        false
      rescue RuntimeError
        errors.add(:base, :access_denied)
        false
      end

      private

      def check_timeout
        @data = PHP.unserialize(@user_session.data)

        unless @data['authed'] && Time.zone.now < (Time.zone.at(@user_session.last_access) + @user_session.timeout)
          raise 'abort'
        end
      end
    end
  end
end
