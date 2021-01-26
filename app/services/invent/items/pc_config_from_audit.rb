module Invent
  module Items
    # Получить данные о конфигурации ПК от системы Аудит.
    class PcConfigFromAudit < Invent::ApplicationService
      # Устройства, которые не нужно контролировать.
      NOT_DETECTED_DEVICES = [
        'jetflash transcend 4gb',
        'jetflash transcend 8gb',
        'jetflash transcend 16gb',
        'jetflash transcend 64gb',
        'configmgr remote control driver',
        'generic- compact flash',
        'generic- ms/ms-pro',
        'generic- sm/xd-picture',
        'generic- sd/mmc',
        'sd card'
      ].freeze
      # Время, отведенное для выполнения запроса
      TIMEOUT_FOR_REQUEST = 28

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
        Timeout.timeout(TIMEOUT_FOR_REQUEST) do
          loop do
            begin
              @data = load_configuration_data

              if data.nil?
                errors.add(:base, :empty_data)
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

      def load_configuration_data
        raw_data = Audit.configuration_data(@host.mac)
        Rails.logger.info "Raw data: #{raw_data.inspect}".blue
        return nil if raw_data.empty?

        processing_pc_data(raw_data[0])
      end

      # Обработка данных, полученных с Аудита.
      # data - данные, полученные с Аудита
      def processing_pc_data(data)
        data.delete('printers')
        data.each do |type, value|
          value = value.to_s

          data[type] = []

          value.split(';').map do |val|
            val.strip!
            val.gsub!(/ +/, ' ')

            # Игнорировать результат нахождения флэшек.
            next if NOT_DETECTED_DEVICES.include? val

            # Перевести значения ОЗУ из Мб в Гб. Округление по 512Мб.
            if type == 'ram'
              tmp_ram = (val.to_f / 1024).round(1)
              mod_part = tmp_ram.to_s.split('.')
              if mod_part[1].to_i <= 5 && mod_part[1].to_i != 0
                mod_part[1] = 5
                val = mod_part.join('.').to_f
              else
                val = tmp_ram.ceil
              end
            end

            data[type].push val
          end
        end

        data
      end
    end
  end
end
