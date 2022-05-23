require 'prawn'

class StatisticsOrderWorker
  include Sidekiq::Worker

  def perform(*_args)
    generate_file
  end

  protected

  # Перевод чисел месяцев в названия
  def translate(num)
    array = {
                '1': 'Январь',
                '2': 'Февраль',
                '3': 'Март',
                '4': 'Апрель',
                '5': 'Май',
                '6': 'Июнь',
                '7': 'Июль',
                '8': 'Август',
                '9': 'Сентябрь',
                '10': 'Октябрь',
                '11': 'Ноябрь',
                '12': 'Декабрь'
            }
    array[num.to_sym]
  end

  def generate_file
    # [выдано на РМ, сдано на склад, списано]
    counts = [0, 0, 0]

    # Статистика за предыдущий месяц
    last_month = Time.zone.now.month == 1 ? 12 : Time.zone.now.month - 1

    # 1 число предыдущего месяца
    start_date = Time.new(Time.zone.now.year, last_month, Time.zone.now.day)

    # 1 число текущего месяца
    end_date = Time.zone.now

    list_type_item = ['Системный блок', 'Моноблок']

    operations = Warehouse::Operation
                   .includes(:operationable)
                   .where(operationable_type: 'Warehouse::Order', status: 'done')
                   .where('date >= ?', start_date)
                   .where('date < ?', end_date)

    operations.each do |op|
      next unless list_type_item.include?(op.item_type) && op.operationable.present?

      case op.operationable.operation
      when 'out'
        counts[0] += 1
      when 'in'
        counts[1] += 1
      when 'write_off'
        counts[2] += 1
      end
    end

    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(name: "#{translate(last_month.to_s)}") do |sheet|
        title = sheet.styles.add_style(
          b: true,
          sz: 14,
          fg_color: "#FF000000",
          border: Axlsx::STYLE_THIN_BORDER,
          alignment: { horizontal: :center }
        )

        data = sheet.styles.add_style(
          sz: 14,
          bg_color: "e2f0d9",
          fg_color: "#FF000000",
          border: Axlsx::STYLE_THIN_BORDER,
          alignment: { horizontal: :center }
        )

        sheet.add_row ['Выдано на РМ, шт', 'Сдано на склад, шт', 'Списано, шт'], style: title
        sheet.add_row [counts[0], counts[1], counts[2]], style: data
      end

      StatisticsOrderMailer.report_email(p.to_stream.read, translate(last_month.to_s)).deliver
    end

    Sidekiq.logger.info "Статистика отправлена за #{translate(last_month.to_s).downcase}: #{counts}"
  end
end
