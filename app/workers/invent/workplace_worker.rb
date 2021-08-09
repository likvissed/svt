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

    Invent::Workplace.where(workplace_id: ids).update_all(status: :freezed) if ids.any?
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
    Rails.logger.info "ids: #{ids}" if ids.present?
  end

  # Очистить кэш, для того, чтобы обновлённые статусы отображались у пользователей
  def clear_cache
    Rails.cache.clear
  end

  def ids_workplace_not_used
    workplaces = Invent::Workplace.where(status: :confirmed).includes(:workplace_count, :items)
    array_id_tn = workplaces.map(&:id_tn).compact.uniq.join(',')
    employees = UsersReference.info_users("id=in=(#{array_id_tn})").map { |employee| employee.slice('id', 'departmentForAccounting') }

    workplaces.find_each.map do |wp|
      # Совпадает ли отдел с отделом пользователя на этом РМ
      match = employees.find { |value| value['departmentForAccounting'] == wp.division.to_i && value['id'] == wp.id_tn }

      next if match.present? && wp.items.size.positive?

      wp.workplace_id
    end.compact
  end

  def ids_workplace_in_decree
    # Поиск всех пользователей в декрете
    UsersReference.info_users("vacation=='#{CGI.escape('Декретный отпуск')}'").map { |employee| employee.slice('id', 'vacationTo') }
  end
end
