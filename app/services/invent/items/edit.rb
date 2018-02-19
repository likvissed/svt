module Invent
  module Items
    # Загрузить данные по указанной технике
    class Edit < Invent::ApplicationService
      def initialize(item_id)
        @item_id = item_id
      end

      def run
        show = Show.new(@item_id)

        if show.run
          @data = show.data
          data['status'] = :waiting_take

          prepare_to_edit_item(data)
        else
          raise 'Сервис Show не отработал'
        end

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end
    end
  end
end
