module Invent
  module LkInvents
    class BaseService < ApplicationService
      private

      def prepare_to_***REMOVED***_table(wp)
        wp['short_description'] = wp['workplace_type']['short_description'] if wp['workplace_type']
        wp['fio'] = wp['user_iss'] ? wp['user_iss']['fio_initials'] : 'Ответственный не найден'
        wp['duty'] = wp['user_iss'] ? wp['user_iss']['duty'] : 'Ответственный не найден'
        wp['location'] = "Пл. '#{wp['iss_reference_site']['name']}', корп.
#{wp['iss_reference_building']['name']}, комн. #{wp['iss_reference_room']['name']}"
        wp['status'] = Workplace.translate_enum(:status, wp['status'])

        wp.delete('iss_reference_site')
        wp.delete('iss_reference_building')
        wp.delete('iss_reference_room')
        wp.delete('user_iss')
        wp.delete('workplace_type')

        wp
      end

      # Получить список работников указанного отдела.
      def load_users
        data[:users] = UserIss.select(:id_tn, :fio).where(dept: @division)
      end
    end
  end
end
