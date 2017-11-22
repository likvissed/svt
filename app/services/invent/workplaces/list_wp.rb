module Invent
  module Workplaces
    # Загрузить все рабочие места
    class ListWp < ApplicationService
      # init_filters- флаг, определяющий, нужно ли загрузить данные для фильтров.
      # filters - объект, содержащий выбранные фильтры.
      def initialize(init_filters = false, filters = false)
        @data = {}
        @init_filters = init_filters
        @filters = filters
      end

      def run
        load_workplace
        run_filters if @filters
        prepare_to_render
        load_filters if @init_filters

        true
      end

      private

      def load_workplace
        @workplaces = Workplace.includes(
          :user_iss,
          :workplace_type,
          :workplace_specialization,
          :workplace_count,
          :iss_reference_site,
          :iss_reference_building,
          :iss_reference_room,
          inv_items: [:inv_type, :inv_model, inv_property_values: %i[inv_property inv_property_list]]
        ).where(status: :pending_verification)
      end

      # Отфильтровать полученные данные
      def run_filters
        unless @filters['workplace_count_id'].to_i.zero?
          @workplaces = @workplaces.where(workplace_count_id: @filters['workplace_count_id'])
        end
      end

      def prepare_to_render
        @data[:workplaces] = @workplaces.as_json(
          include: [
            :user_iss,
            :workplace_type,
            :workplace_specialization,
            :workplace_count,
            :iss_reference_site,
            :iss_reference_building,
            :iss_reference_room,
            inv_items: {
              include: [
                :inv_type,
                :inv_model,
                inv_property_values: {
                  include: %i[inv_property inv_property_list]
                }
              ]
            }
          ]
        ).map do |wp|
          workplace = "ФИО: #{wp['user_iss']['fio']}; Отдел: #{wp['workplace_count']['division']};
 #{wp['workplace_type']['short_description']}; Расположение: #{wp_location_string(wp)}; Основной вид деятельности:
 #{wp['workplace_specialization']['short_description']}"
          items = wp['inv_items'].map { |item| item_info(item) }

          {
            workplace_id: wp['workplace_id'],
            workplace: workplace,
            items: items
          }
        end
      end

      # Преобразовать данные о составе РМ в массив строк.
      def item_info(item)
        model = get_model(item)
        property_values = item['inv_property_values'].map { |prop_val| property_value_info(prop_val) }

        "#{item['inv_type']['short_description']}: Инв №: #{item['invent_num']}; #{model}; Конфигурация:
 #{property_values.join('; ')}"
      end

      # Загрузить данные для фильтров
      def load_filters
        @data[:filters] = {}
        @data[:filters][:divisions] = WorkplaceCount.select(:workplace_count_id, :division).order('CAST(division AS SIGNED)')
      end
    end
  end
end
