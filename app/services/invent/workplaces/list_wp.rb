module Invent
  module Workplaces
    # Загрузить все рабочие места
    class ListWp < BaseService
      def initialize(current_user, params)
        @current_user = current_user
        @start = params[:start]
        @length = params[:length]
        @conditions = JSON.parse(params[:filters]) if params[:filters]

        super
      end

      def run
        load_workplace
        limit_records
        prepare_to_render

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def load_workplace
        data[:recordsTotal] = Workplace.count
        @workplaces = policy_scope(Workplace)
        run_filters if @conditions
      end

      def limit_records
        data[:recordsFiltered] = @workplaces.length
        @workplaces = @workplaces
                        .includes(
                          :user_iss,
                          :workplace_type,
                          :workplace_specialization,
                          :workplace_count,
                          :iss_reference_site,
                          :iss_reference_building,
                          :iss_reference_room,
                          items: [:type, :model, property_values: %i[property property_list]]
                        ).order(workplace_id: :desc).limit(@length).offset(@start)
      end

      def prepare_to_render
        data[:data] = @workplaces
                        .as_json(
                          include: [
                            :user_iss,
                            :workplace_type,
                            :workplace_specialization,
                            :workplace_count,
                            :iss_reference_site,
                            :iss_reference_building,
                            :iss_reference_room,
                            items: {
                              include: [
                                :type,
                                :model,
                                property_values: {
                                  include: %i[property property_list]
                                }
                              ],
                              methods: :short_item_model
                            }
                          ]
                        ).map do |wp|
                          fio = wp['user_iss'] ? wp['user_iss']['fio'] : wrap_problem_string('Ответственный не найден')
                          workplace = "ФИО: #{fio}; Отдел: #{wp['workplace_count']['division']};
#{wp['workplace_type']['short_description']}; Расположение: #{wp_location_string(wp)}; Основной вид деятельности:
#{wp['workplace_specialization']['short_description']}"
                          items = wp['items'].map { |item| item_info(item) }

                          {
                            workplace_id: wp['workplace_id'],
                            workplace: workplace,
                            items: items
                          }
                        end
      end

      # Преобразовать данные о составе РМ в массив строк.
      def item_info(item)
        model = item['short_item_model'].blank? ? 'не указана' : item['short_item_model']
        property_values = item['property_values'].map { |prop_val| property_value_info(prop_val) }

        "#{item['type']['short_description']}: Инв №: #{item['invent_num']}; Модель: #{model}; Конфигурация:
 #{property_values.join('; ')}"
      end

      # Обернуть строку в тег <span class='manually'>
      def wrap_problem_string(string)
        "<span class='manually-val'>#{string}</span>"
      end
    end
  end
end
