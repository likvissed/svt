module Invent
  module LkInvents
    # Класс проверяет доступ к разделу "Вычислительная техника" для указанного табельного номера.
    class SvtAccess < BaseService
      def initialize(tn)
        @tn = tn
        @data = {
          access: nil,
          list: []
        }
      end

      def run
        check_access
        true
      end

      private

      def check_access
        @user = User.includes(:workplace_counts).find_by(tn: @tn)

        if @user&.workplace_counts.try(:any?)
          @data[:access] = true
          @user.workplace_counts.each do |wp_c|
            @data[:list] << { workplace_count_id: wp_c.workplace_count_id, division: wp_c.division }
          end
        else
          @data[:access] = false
        end
      end
    end
  end
end
