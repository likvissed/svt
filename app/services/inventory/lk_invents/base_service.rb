module Inventory
  module LkInvents
    class BaseService
      def prepare_to_***REMOVED***_table(wp)
        wp['short_description'] = wp['workplace_type']['short_description'] if wp['workplace_type']
        wp['fio'] = wp['user_iss']['fio_initials']
        wp['duty'] = wp['user_iss']['duty']
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
    end
  end
end
