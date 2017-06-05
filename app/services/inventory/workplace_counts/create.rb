module Inventory
  module WorkplaceCounts
    # Класс создает новый отдел, для заполнения данными о РМ.
    class Create < ApplicationService
      attr_reader :error

      # strong_params - данные, прошедшие фильтрацию strong_params.
      def initialize(strong_params)
        @error = {}
        @wpc_params = strong_params
        @***REMOVED***_role = Role.find_by(name: :***REMOVED***_user)
      end

      def run
        @data = WorkplaceCount.new(@wpc_params)
        get_responsible_data
        save_workplace
      rescue RuntimeError
        false
      end

      private

      # Получить данные об ответственных.
      def get_responsible_data
        return if @wpc_params['users_attributes'].nil?

        # Найти каждого пользователя в таблице UserIss.
        data.users.each do |resp|
          @user = UserIss.find_by(tn: resp.tn)

          check_user(resp) if @user
        end
      end

      # Проверить, существует ли в таблице 'users' указанный пользователь. Если да - проверить, изменился ли номер
      # телефона. Если нет - дополнить элемент массива users необходимыми полями.
      # resp - создаваемый пользователь
      def check_user(resp)
        return if User.find_by(id_tn: @user.id_tn)

        resp.id_tn = @user.id_tn
        resp.tn = @user.tn
        resp.phone = @user.tel if resp.phone.empty?
        resp.role = @***REMOVED***_role
      end

      # Сохранить отдел
      def save_workplace
        return true if data.save

        error[:object] = data.errors
        error[:full_message] = data.errors.full_messages.join('. ')

        raise 'abort'
      end
    end
  end
end