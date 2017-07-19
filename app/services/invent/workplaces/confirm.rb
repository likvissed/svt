module Invent
  module Workplaces
    # Подтверждение/отклонение конфигурации РМ
    class Confirm < ApplicationService
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

        true
      rescue RuntimeError
        false
      end

      private

      def load_workplaces
        @workplaces = Workplace.where(workplace_id: @ids)
      end

      def update_workplaces
        case @type
        when 'confirm'
          @workplaces.find_each { |wp| wp.update(status: :confirmed) }
          @data = 'Данные подтверждены'
        when 'disapprove'
          @workplaces.find_each { |wp| wp.update(status: :disapproved) }
          @data = 'Данные отклонены'
        else
          errors.add(:base, 'Указанное действие неразрешено')
          raise 'abort'
        end
      end
    end
  end
end
