module Invent
  module LkInvents
    # Проверить запись по указанному sid в таблице user_session. Это необходимо, чтобы убедиться, что
    # пользователь действительно авторизован в ЛК
    class LkAuthorization < BaseService
      attr_reader :user_session, :session_data

      # sid - SID пользователя в ЛК
      def initialize(sid)
        @data = {}
        @sid = sid
      end

      def run
        @user_session = UserSession.find(@sid)
        check_timeout
        find_user

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      rescue ActiveRecord::RecordNotFound
        errors.add(:base, :access_denied)

        false
      end

      protected

      # Проверяем, действительно ли авторизован пользователь в ЛК.
      def check_timeout
        @session_data = PHP.unserialize(user_session.data)
        return if session_data['authed'] && Time.zone.now < (Time.zone.at(user_session.last_access) + UserSession.time_out)

        raise 'Время сессии истекло'
      end

      # Найти пользователь в локальной таблице users (т.о. проверяем, есть ли у пользователя доступ к сайту).
      def find_user
        raise 'Доступ запрещен' if (@data = User.find_by(tn: session_data['user_id'])).nil?
      end
    end
  end
end
