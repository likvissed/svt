module Invent
  module Workplaces
    # Получить данные о РМ.
    class Edit < BaseService
      # current_uer - текущий пользовтаель
      # workplace_id - workplace_id рабочего места
      def initialize(current_user, workplace_id)
        @current_user = current_user
        @workplace_id = workplace_id

        super
      end

      # format - тип запроса (html или json)
      def run(format)
        case format
        when :html
          load_workplace_html
        when :json
          load_workplace_json
        else
          raise 'Неизвестный формат данных. Ожидается html или json запрос'
        end

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      # Загрузить объект РМ.
      def load_workplace_html
        @data = Workplace.find(@workplace_id)
        authorize @data, :edit?
      end

      # Загрузить все данные о РМ и все необходимые свойства (все типы оборудования, типы РМ, их возможные свойства,
      # виды деятельности и расположения).
      def load_workplace_json
        load_workplace
        load_properties
      end

      def load_workplace
        @edit_workplace = LkInvents::EditWorkplace.new(@current_user, @workplace_id)
        return data[:wp_data] = @edit_workplace.data if @edit_workplace.run
        raise 'LkInvents::EditWorkplace не отработал'
      end

      def load_properties
        properties = LkInvents::InitProperties.new(@current_user, @edit_workplace.workplace.division)
        return data[:prop_data] = properties.data if properties.run
        raise 'LkInvents::InitProperties не отработал'
      end
    end
  end
end
