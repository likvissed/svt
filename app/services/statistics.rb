class Statistics < ApplicationService
  def initialize
    super
  end

  def run(type)
    if type.to_s == 'ups_battery'
      stat = Invent::Statistics::UpsBattery.new
    end

    if stat&.run
      @data = stat.data
    else
      raise 'Сервис завершился с ошибкой'
    end

    true
  rescue RuntimeError => e
    Rails.logger.error e.inspect.red
    Rails.logger.error e.backtrace[0..5].inspect

    false
  end
end
