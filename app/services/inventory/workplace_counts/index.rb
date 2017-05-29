module Inventory
  module WorkplaceCounts
    class Index < ApplicationService
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
                              .joins('LEFT OUTER JOIN invent_workplace r ON r.workplace_id = invent_workplace_count
.workplace_count_id and r.status = 0')
                              .joins('LEFT OUTER JOIN invent_workplace w ON w.workplace_count_id =
 invent_workplace_count.workplace_count_id and w.status = 1')
                              .includes(:workplace_responsibles, :users)
                              .select('invent_workplace_count.*, COUNT(r.workplace_id) as ready, COUNT(w
.workplace_id) as waiting')
                              .group('invent_workplace_count.workplace_count_id')
      end

      def transform_to_json
        @data = @workplace_counts.as_json(
          include: {
            workplace_responsibles: {
              only: %i[id_tn phone],
              include: {
                user: {
                  only: %i[tn fullname]
                }
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

          c['workplace_responsibles'].each do |resp|
            c['responsibles'] << resp['user_iss']['fio'] unless resp['user_iss'].nil?
            c['phones'] << resp['phone'] unless resp['phone'].empty?
          end

          c['responsibles'] = c['responsibles'].join(', ')
          c['phones'] = c['phones'].join(', ')
        end
      end
    end
  end
end
