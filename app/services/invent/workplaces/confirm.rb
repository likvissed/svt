module Invent
  module Workplaces
    # Подтверждение/отклонение конфигурации РМ
    class Confirm < BaseService
      # type - вид действия: confirm - подтвердить, disapprove - отклонить
      # ids - массив, содержащий workplace_id рабочих мест
      def initialize(type, ids)
        @type = type
        @ids = ids
      end

      def run
        load_workplaces
        update_workplaces
        broadcast_workplaces
        broadcast_workplace_list

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      private

      def load_workplaces
        @workplaces = Workplace.where(workplace_id: @ids)
      end

      def update_workplaces
        errors_arr = []

        case @type
        when 'confirm'
          @workplaces.find_each { |wp| errors_arr << wp.workplace_id unless wp.update_attribute('status', :confirmed) }
          @data = 'Данные подтверждены'
        when 'disapprove'
          @workplaces.find_each { |wp| errors_arr << wp.workplace_id unless wp.update_attribute('status', :disapproved) }
          @data = 'Данные отклонены'
        else
          errors.add(:base, :unknown_action)
          raise 'Неизвестное действие.'
        end

        return if errors_arr.empty?
        errors.add(:base, :error_update_status, workplaces: errors_arr.join(', '))
        raise 'Статус не обновлен'
      end
    end
  end
end
