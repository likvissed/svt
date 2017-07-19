module Invent
  module WorkplaceCounts
    class Show < ApplicationService
      def initialize(workplace_count_id)
        @workplace_count_id = workplace_count_id
      end

      def run
        load_workplace_count
      rescue RuntimeError
        false
      end

      def load_workplace_count
        @data = WorkplaceCount.includes(:users).find(@workplace_count_id)

        transform_to_json
        prepare_to_render
      end

      def transform_to_json
        @data = data.as_json(include: { users: { only: %i[id tn fullname phone] } })
      end

      def prepare_to_render
        data['users_attributes'] = data['users']
        data.delete('users')
      end
    end
  end
end
