class Audit < SMSServer
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
  # Максимальное количество дней, по истечению которых данные от Аудита считаются устаревшими.
  MAX_RELENAVCE_TIME = 20
  # Время, отведенное для выполнения запроса
  TIMEOUT_FOR_REQUEST = 28

  # Выполнить хранимую процедуру на сервере smssvr.
  # pc_name - имя компьютера
  def self.get_data(pc_name)
    raw_data = execute_procedure('ISS_Get_HW_invent_inf', pc_name, 'f')
    logger.info "Raw data: #{raw_data.inspect}".blue

    return nil if raw_data.empty?

    data = raw_data[0]

    # data.delete('last_connection')
    data.delete('printers')

    data.each do |type, value|
      data[type] = []

      value.split(';').map do |val|
        val.strip!

        # Игнорировать результат нахождения флэшек.
        next if NOT_DETECTED_DEVICES.include? val

        # Перевести значения ОЗУ из Кб в Гб. Округление по 512Мб.
        if type == 'ram'
          tmp_ram = val.to_f / 1024 / 1024
          val = format('%.1f', tmp_ram)
          mod_part = val.split('.')

          if mod_part[1].to_i <= 5
            mod_part[1] = 5
            val = eval(mod_part.join('.'))
          else
            val = val.to_f.ceil
          end
        end

        data[type].push val
      end
    end

    data
  end

  # Проверка актуальности данных по полю last_connection (всё, что более 20 дней - устаревшие данные).
  def self.relevance?(data)
    Time.zone.parse(data[:last_connection].first) + MAX_RELENAVCE_TIME.days > Time.zone.now
  end
end
