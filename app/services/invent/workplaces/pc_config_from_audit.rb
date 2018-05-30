module Invent
  module Workplaces
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

        super
      end

      def run
        run_callbacks(:run) do
          host_name
          load_data
        end
      rescue Timeout::Error
        errors.add(:base, :not_responded)
        false
      rescue RuntimeError => e
        Rails.logger.error e.inspect.red
        Rails.logger.error e.backtrace[0..5].inspect

        false
      end

      protected

      def run_validations
        raise 'Ошибка валидации' unless valid?
      end

      def host_name
        @host = HostIss.find_by(id: inv_num)
        return if @host

        errors.add(:host, :not_found)
        raise 'Хост не найден'
      end

      def load_data
        Timeout.timeout(Audit::TIMEOUT_FOR_REQUEST) do
          loop do
            begin
              @data = Audit.get_data(host.name)
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
    end
  end
end
