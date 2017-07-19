module Invent
  module LkInvents
    # Получить данные о конфигурации ПК от системы Аудит.
    class PcConfigFromAudit < BaseService
      attr_reader :host
      attr_accessor :inv_num

      validates :inv_num, presence: true, allow_blank: false

      define_model_callbacks :run

      before_run :run_validations

      # Инвентарный номер ПК
      def initialize(inv_num)
        @inv_num = inv_num
      end

      def run
        run_callbacks(:run) do
          host_name
          load_data
        end
      rescue Timeout::Error
        errors.add(:base, :not_responded)
        false
      rescue RuntimeError
        false
      end

      private

      def run_validations
        raise 'abort' unless valid?
      end

      def load_data
        Timeout.timeout(Audit::TIMEOUT_FOR_REQUEST) do
          loop do
            begin
              @data = Audit.get_data(host[:name])
              if data.nil?
                errors.add(:base, :empty_data)
                return false
              elsif !Audit.relevance?(data)
                errors.add(:base, :not_relevant)
                return false
              end

              break
            rescue StandardError
              errors.add(:base, :not_responded)
              return false
            end
          end
        end

        true
      end

      def host_name
        @host = HostIss.get_host(inv_num)
        return if @host

        errors.add(:host, :not_found)
        raise 'abort'
      end
    end
  end
end
