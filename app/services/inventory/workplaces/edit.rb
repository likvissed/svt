module Inventory
  module Workplaces
    # Получить данные о РМ.
    class Edit < ApplicationService
      # current_uer - текущий пользовтаель
      # workplace_id - workplace_id рабочего места
      def initialize(current_user, workplace_id)
        @data = {}
        @current_user = current_user
        @workplace_id = workplace_id
      end

      # format - тип запроса (html или json)
      def run(format)
        case format
        when :html
          load_workplace_html
        when :json
          load_workplace_json
        else
          raise 'abort'
        end

        true
      rescue RuntimeError
        false
      end

      private

      # Загрузить объект РМ.
      def load_workplace_html
        @data = Workplace.find(@workplace_id)
      end

      # Загрузить все данные о РМ и все необходимые свойства (все типы оборудования, типы РМ, их возможные свойства,
      # виды деятельности и расположения).
      def load_workplace_json
        load_workplace
        load_properties
      end

      def load_workplace
        @edit_workplace = LkInvents::EditWorkplace.new(@current_user, @workplace_id)
        if @edit_workplace.run
          data[:wp_data] = @edit_workplace.data
        else
          raise 'abort'
        end
      end

      def load_properties
        properties = LkInvents::InitProperties.new(nil, @edit_workplace.workplace.division)
        if properties.run
          data[:prop_data] = properties.data
        else
          raise 'abort'
        end
      end
    end
  end
end
