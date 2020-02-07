module Invent
  module WorkplaceCounts
    class Create < Invent::ApplicationService
      def initialize(current_user, workplace_count_params)
        @current_user = current_user
        @workplace_count_params = workplace_count_params

        super
      end

      def run
        users_attributes if @workplace_count_params.key?(:users_attributes)
        save_workplace_count

        true
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def users_attributes
        @workplace_count_params[:users_attributes].each do |user_attr|
          user_iss = UserIss.find_by(tn: user_attr[:tn])

          user = User.find_by(tn: user_attr[:tn])

          user_attr[:role_id] = if user
                                  user.role_id
                                else
                                  Role.find_by(name: '***REMOVED***_user').id
                                end

          next unless user_iss

          user_attr[:id] = user.try(:id)
          @workplace_count_params[:user_ids].push(user_attr[:id])
          user_attr[:id_tn] = user_iss.id_tn
          user_attr[:fullname] = user_iss.fio

          user_attr[:phone] = user_attr[:phone].presence || user_iss.tel
        end
      end

      def save_workplace_count
        workplace_count = WorkplaceCount.new(@workplace_count_params)
        authorize workplace_count, :create?

        return true if workplace_count.save

        error[:object] = workplace_count.errors
        error[:full_message] = workplace_count.errors.full_messages.join('. ')
        raise 'Данные не обновлены'
      end
    end
  end
end
