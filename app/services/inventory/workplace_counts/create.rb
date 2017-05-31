module Inventory
  module WorkplaceCounts
    # Класс создает новый отдел, для заполнения данными о РМ
    class Create < ApplicationService
      attr_reader :error

      # strong_params - данные, прошедшие фильтрацию strong_params
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

      # Получить данные об ответственных
      def get_responsible_data
        return if @wpc_params['users_attributes'].nil?

        # Массив табельных номеров, по которым не удалось найти даныне в таблице UserIss
        tn_errors = []
        # Избавиться от пользователей с одинаковыми инвентарными
        @data.users = @data.users.to_a.uniq { |u| u.tn }
        # Найти каждого пользователя в таблице UserIss
        @data.users.each do |resp|
          user = UserIss.find_by(tn: resp.tn)

          if user.nil?
            tn_errors << resp.tn
          else
            check_user(resp, user)
          end
        end

        @data.users = @data.users.to_a.reject { |u| u.reject }

        # Добавить ошибку в объект @data, если в таблице UserIss информация об ответственном не найдена.
        @data.errors.add(:base, :user_not_found, tn: tn_errors.join(', ')) unless tn_errors.empty?
      end

      # Проверить, существует ли в таблице users указанный пользователь. Если да - удалить пользователя из массива
      # users и добавить запись в объект workplace_responsibles. Если нет - дополнить элемент массива users
      # необходимыми полями.
      # resp - создаваемый пользователь
      # user - объект таблицы UserIss
      def check_user(resp, user)
        if (local_user = User.find_by(id_tn: user.id_tn)).nil?
          resp.id_tn = user.id_tn
          resp.tn = user.tn
          resp.phone = user.tel if resp.phone.empty?
          resp.role = @***REMOVED***_role
        else
          resp.reject = true

          @data.workplace_responsibles.build(user: local_user)
        end
      end

      # Сохранить отдел
      def save_workplace
        return true if @data.save

        error[:object] = @data.errors
        error[:full_message] = @data.errors.full_messages.join('. ')
        raise 'abort'
      end
    end
  end
end
