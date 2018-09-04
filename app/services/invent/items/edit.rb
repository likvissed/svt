module Invent
  module Items
    # Загрузить данные по указанной технике
    class Edit < Invent::ApplicationService
      def initialize(item_id, with_init_props = false)
        @item_id = item_id
        @with_init_props = with_init_props

        super
      end

      def run
        load_item
        prepare_to_edit_item(data[:item])
        load_properties if @with_init_props

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def load_item
        show = Show.new({ item_id: @item_id })

        raise 'Сервис Show не отработал' unless show.run

        data[:item] = show.data.first
        # data['status'] = :prepared_to_swap
      end

      def load_properties
        properties = LkInvents::InitProperties.new(@current_user)
        return data[:prop_data] = properties.data if properties.run

        raise 'Ошибка сервиса LkInvents::InitProperties'
      end
    end
  end
end
