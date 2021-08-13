class Invent::WorkplaceWorker
  include Sidekiq::Worker

  def perform(*_args)
    freezing_not_used_workplaces
    freezing_temporary_workplaces
    freezing_decree_workplaces

    clear_cache

    filter_data_before_send_mail
  end

  protected

  # Заморозить РМ, у которых отсутствует ответственный или список привязанной техники
  def freezing_not_used_workplaces
    @ids_not_used = ids_workplace_not_used

    if @ids_not_used.any?
      Sidekiq.logger.info "freezing_not_used_workplaces: #{@ids_not_used}"
      Invent::Workplace.where(workplace_id: @ids_not_used).update_all(status: :freezed)
    end
  end

  # Заморозить временные РМ, у которых прошел срок работы.
  def freezing_temporary_workplaces
    workplaces = Invent::Workplace.where(status: 'temporary').where('freezing_time <= ?', Time.zone.now)

    if workplaces.present?
      @ids_was_temporary = workplaces.pluck(:workplace_id)

      Sidekiq.logger.info "freezing_temporary_workplaces: #{@ids_was_temporary}"
      Invent::Workplace.where(workplace_id: @ids_was_temporary).update_all(status: :freezed)
    end
  end

  # Заморозить РМ тех, кто в декрете и если имеется техника
  def freezing_decree_workplaces
    employees_in_decree = ids_workplace_in_decree
    workplaces = Invent::Workplace.where(status: :confirmed).includes(items: :type)
    @ids_decree = []

    workplaces.find_each do |wp|
      # Найти пользователей в декрете, у которых имеются РМ
      match = employees_in_decree.find { |value| value['id'] == wp.id_tn }

      next unless match.present? && wp.items.size.positive?

      fio = fio_initials(match.try(:[], 'fullName'))
      date = Time.zone.parse(match.try(:[], 'vacationTo')).strftime('%d-%m-%Y')

      message = "/ #{fio} в декрете до #{date} /"

      # Если записи об окончании декрета нет, то добавить
      # (Для того, чтобы одинаковые записи не дублировались)
      if wp.comment.nil? || wp.comment.to_s.exclude?(message)
        wp.comment = "#{wp.comment} #{message}"
        wp.save(validate: false)
      end

      # Для получения замороженных в данный момент массива id РМ
      @ids_decree << wp.workplace_id
    end

    if @ids_decree.present?
      Sidekiq.logger.info "freezing_decree_workplaces: #{@ids_decree}"
      Invent::Workplace.where(workplace_id: @ids_decree).update_all(status: :freezed)
    end
  end

  # Очистить кэш, для того, чтобы обновлённые статусы отображались у пользователей
  def clear_cache
    Rails.cache.clear
  end

  def ids_workplace_not_used
    ids = []
    workplaces = Invent::Workplace.includes(:workplace_count, :items).where(status: :confirmed)

    # Для того, чтобы предотвратить ошибку большого запроса в НСИ
    workplaces.each_slice(500) do |wps|
      employee_list = wps.map(&:id_tn).compact.uniq.join(',')
      employees = UsersReference.info_users("id=in=(#{employee_list})")

      wps.each do |wp|
        match = employees.find { |value| value['id'] == wp.id_tn }

        # Если пользователь существует и у него соответствует отдел -  отделу на РМ
        next if match.present? && match['departmentForAccounting'] == wp.division.to_i && wp.items.size.positive?

        ids << wp.workplace_id
      end
    end
    ids
  end

  def ids_workplace_in_decree
    # Поиск всех пользователей в декрете
    UsersReference.info_users("vacation=='#{CGI.escape('Декретный отпуск')}'").map { |employee| employee.slice('id', 'vacationTo', 'fullName') }
  end

  def fio_initials(fullname)
    array = fullname.split(' ')

    "#{array[0]} #{array[1][0]}.#{array[2][0]}."
  end

  # Распределить замороженные РМ на 2 вида: основная техника или печатная
  def filter_data_before_send_mail
    @types_print = %w[printer plotter scanner mfu copier print_server 3d_printer print_system shredder].freeze
    @office_equipment = Invent::Type.where.not(name: @types_print).pluck(:name)

    # Оргтехника
    @not_used_one = []
    @decree_one = []
    @was_temporary_one = []
    # Печатная техника
    @not_used_two = []
    @decree_two = []
    @was_temporary_two = []

    @workplaces = Invent::Workplace.includes(items: :type).where(status: :freezed)

    if @ids_not_used.present?
      result = sort_items(@ids_not_used)

      @not_used_one = result[0]
      @not_used_two = result[1]
    end

    if @ids_decree.present?
      result = sort_items(@ids_decree)

      @decree_one = result[0]
      @decree_two = result[1]
    end

    if @ids_was_temporary.present?
      result = sort_items(@ids_was_temporary)

      @was_temporary_one = result[0]
      @was_temporary_two = result[1]
    end

    Invent::WorkplaceFreezeMailer.send_email(@not_used_one, @decree_one, @was_temporary_one).deliver if @not_used_one.present? || @decree_one.present? || @was_temporary_one.present?
    Invent::WorkplaceFreezeMailer.send_email_print(@not_used_two, @decree_two, @was_temporary_two).deliver if @not_used_two.present? || @decree_two.present? || @was_temporary_two.present?
  end

  # Распределение замороженных РМ по содержанию в них оргтехники и печатающих устройств
  def sort_items(ids)
    @items_one = []
    @items_two = []

    @workplaces.where(workplace_id: ids).find_each do |wp|
      if wp.items.blank?
        @items_one << wp.workplace_id
        break
      end

      types = wp.items.map { |it| it.type.name }

      @items_one << wp.workplace_id if types.any? { |type| @office_equipment.include?(type) }
      @items_two << wp.workplace_id if types.any? { |type| @types_print.include?(type) }
    end

    [@items_one, @items_two]
  end
end
