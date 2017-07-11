module Standart
  class Log < ApplicationRecord
    has_many :log_details

    belongs_to :system_unit

    validates :system_unit_id, :event, presence: true
    # валидацию :user_id добавить, когда появится таблица users

    enum event: ['Эталон создан', 'Эталон изменен', 'Изменения подтверждены']
  end
end
