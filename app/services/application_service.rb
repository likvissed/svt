class ApplicationService
  include Pundit
  include ActiveModel::Validations

  attr_reader :data, :current_user, :error

  # Получить модель в виде строки
  def get_model(item)
    if item['model']
      "Модель: #{item['model']['item_model']}"
    elsif !item['model'] && !item['item_model'].empty?
      # "<span class='manually-val'>Модель: #{item['item_model']}</span>"
      wrap_problem_string("Модель: #{item['item_model']}")
    else
      'Модель не указана'
    end
  end

  # Обернуть строку в тег <span class='manually'>
  def wrap_problem_string(string)
    "<span class='manually-val'>#{string}</span>"
  end

  # Разослать сообщение о необходимости обновления сводной таблицы рабочих мест.
  def broadcast_workplaces
    ActionCable.server.broadcast 'workplaces', nil
  end
end
