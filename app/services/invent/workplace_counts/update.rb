module Invent
  module WorkplaceCounts
    class Update < Invent::ApplicationService
      def initialize(current_user, workplace_count_id, workplace_count_params)
        @current_user = current_user
        @workplace_count_id = workplace_count_id
        @workplace_count_params = workplace_count_params

        super
      end

      def run
        find_workplace_count
        users_attributes if @workplace_count_params.key?(:users_attributes)
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
        authorize @workplace_count, :update?
      end

      def users_attributes
        @workplace_count_params[:users_attributes].each do |user_attr|
          user_iss = UserIss.find_by(tn: user_attr[:tn])
          user_attr[:phone] = user_attr[:phone].presence || user_iss.tel if user_iss

          if user_attr[:id].blank?
            user = User.find_by(tn: user_attr[:tn])
            user_attr[:role_id] = if user
                                    user.role_id
                                  else
                                    user_attr[:role_id] = Role.find_by(name: '***REMOVED***_user').id
                                  end
            next unless user_iss

            user_attr[:id] = user.try(:id)
            user_attr[:id_tn] = user_iss.id_tn
            user_attr[:fullname] = user_iss.fio
          end
          @workplace_count_params[:user_ids].push(user_attr[:id])
        end
      end

      def update_workplace_count
        return true if @workplace_count.update_attributes(@workplace_count_params)

        error[:object] = @workplace_count.errors
        error[:full_message] = @workplace_count.errors.full_messages.join('. ')
        raise 'Данные не обновлены'
      end
    end
  end
end
