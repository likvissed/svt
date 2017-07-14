module Inventory
  module WorkplaceCounts
    # Класс загружает все данные об отделах, заполняющих данные о РМ, включая отдел, ответственных, телефоны, время доступа для редакитварования,
    # количество ожидающих подстверждения РМ, а также количество подтвержденных РМ
    class Index < ApplicationService
      attr_reader :workplace_counts

      def run
        workplace_counts
        transform_to_json
        prepare_to_render
      rescue RuntimeError
        false
      end

      private

      def workplace_counts
        @workplace_counts = WorkplaceCount
                              .includes(users: :user_iss)
                              .left_outer_joins(:workplaces)
                              .select('invent_workplace_count.*, SUM(CASE WHEN invent_workplace.status = 0 THEN 1 ELSE
 0 END) AS ready, SUM(CASE WHEN invent_workplace.status = 1 THEN 1 ELSE 0 END) AS waiting')
                              .group('invent_workplace_count.workplace_count_id')
      end

      def transform_to_json
        @data = @workplace_counts.as_json(
          include: {
            users: {
              include: {
                user_iss: { only: %i[fio] }
              }
            }
          }
        )
      end

      def prepare_to_render
        @data.each do |c|
          c['date-range'] = "#{c['time_start']} - #{c['time_end']}"
          c['responsibles'] = []
          c['phones'] = []

          c['users'].each do |user|
            next if user['user_iss'].nil?

            c['responsibles'] << user['user_iss']['fio']
            c['phones'] << user['phone'] unless user['phone'].empty?
          end

          c['responsibles'] = c['responsibles'].join(', ')
          c['phones'] = c['phones'].join(', ')
          c['status'] = Time.zone.today.between?(c['time_start'], c['time_end']) ? 'allow' : 'deny'
        end
      end
    end
  end
end
