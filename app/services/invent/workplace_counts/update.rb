module Invent
  module WorkplaceCounts
    class Update < Invent::ApplicationService
      def initialize(workplace_count_id, workplace_count_params)
        @workplace_count_id = workplace_count_id
        @workplace_count_params = workplace_count_params

        super
      end

      def run
        find_workplace_count
        users_attributes if @workplace_count_params.key?('users_attributes')
        update_workplace_count

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def find_workplace_count
        @workplace_count = WorkplaceCount.find(@workplace_count_id)
      end

      def users_attributes
        @workplace_count_params[:users_attributes].each do |user_attr|
          if user_attr[:id].blank?
            user = UserIss.find_by(tn: user_attr['tn'])
            user_attr[:role_id] = Role.find_by(name: '***REMOVED***_user').id
            next unless user

            user_attr[:id] = User.find_by(tn: user_attr['tn']).try(:id)
            user_attr[:id_tn] = user.id_tn
            user_attr[:fullname] = user.fio
            user_attr[:phone] = user_attr[:phone].blank? ? user.tel : user_attr[:phone]
          end
          @workplace_count_params[:user_ids].push(user_attr[:id])
        end
      end

      def update_workplace_count
        return true if @workplace_count.update_attributes(@workplace_count_params)
        # Сбор ошибок

        error[:object] = @workplace_count.errors
        error[:full_message] = @workplace_count.errors.full_messages.join('. ')
        raise 'Данные не обновлены'
      end
    end
  end
end
