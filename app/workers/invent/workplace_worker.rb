class Invent::WorkplaceWorker
  include Sidekiq::Worker

  def perform(*_args)
    freezing_not_used_workplaces
    freezing_temporary_workplaces
    freezing_decree_workplaces
    clear_cache
  end

  protected

  # Заморозить РМ, у которых отсутствует ответственный или список привязанной техники
  def freezing_not_used_workplaces
    ids = ids_workplace_not_used

    if ids.any?
      Sidekiq.logger.info "freezing_not_used_workplaces: #{ids}"
      Invent::Workplace.where(workplace_id: ids).update_all(status: :freezed)
    end
  end

  # Заморозить временные РМ, у которых прошел срок работы.
  def freezing_temporary_workplaces
    Invent::Workplace.where(status: 'temporary').where('freezing_time <= ?', Time.zone.now).update_all(status: :freezed)
  end

  # Заморозить РМ тех, кто в декрете и если имеется техника
  def freezing_decree_workplaces
    employees_in_decree = ids_workplace_in_decree
    workplaces = Invent::Workplace.where(status: :confirmed).includes(:items)
    ids = []

    workplaces.find_each do |wp|
      # Найти пользователей в декрете, у которых имеются РМ
      match = employees_in_decree.find { |value| value['id'] == wp.id_tn }

      next unless match.present? && wp.items.size.positive?

      message = "/ В декрете до #{match.try(:[], 'vacationTo')} /"
      wp.update(status: :freezed, comment: "#{wp.comment} #{message}", disabled_filters: true)

      # Для получения замороженных в данный момент массива id РМ
      ids << wp.workplace_id
    end

    Sidekiq.logger.info "freezing_decree_workplaces: #{ids}" if ids.present?
  end

  # Очистить кэш, для того, чтобы обновлённые статусы отображались у пользователей
  def clear_cache
    Rails.cache.clear
  end

  def ids_workplace_not_used
    ids = []
    # Временно до добавления номера отдела в НСИ
    workplace_count_ids = Invent::WorkplaceCount.where(division: [1001,1002,1003,1004,1005,1006,1007,1008,1009,1010,1011,1012,1013,1014,1015,1016,1017,1018,1019,1020,1021,1022,1023,1024]).pluck(:workplace_count_id)

    workplaces = Invent::Workplace.includes(:workplace_count, :items).where(status: :confirmed).where.not(workplace_count_id: workplace_count_ids)

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
    UsersReference.info_users("vacation=='#{CGI.escape('Декретный отпуск')}'").map { |employee| employee.slice('id', 'vacationTo') }
  end
end
