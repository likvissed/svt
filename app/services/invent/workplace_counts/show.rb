# module Invent
#   module WorkplaceCounts
#     # Загрузить данные доступа отдела.
#     class Show < Invent::ApplicationService
#       def initialize(workplace_count_id)
#         @workplace_count_id = workplace_count_id

#         super
#       end

#       def run
#         load_workplace_count

#         true
#       rescue RuntimeError => e
#         Rails.logger.error e.inspect.red
#         Rails.logger.error e.backtrace[0..5].inspect

#         false
#       end

#       protected

#       def load_workplace_count
#         @data = WorkplaceCount.includes(:users).find(@workplace_count_id)

#         transform_to_json
#         prepare_to_render
#       end

#       def transform_to_json
#         @data = data.as_json(include: { users: { only: %i[id tn fullname phone] } })
#       end

#       def prepare_to_render
#         data['users_attributes'] = data['users']
#         data.delete('users')
#       end
#     end
#   end
# end
