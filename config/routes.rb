Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/callbacks' }

  authenticated :user do
    root 'invent/workplaces#index', as: :authenticated_root
  end

  devise_scope :user do
    root 'devise/sessions#new'
  end

  # Инвентаризация
  namespace :invent do
    # Отделы
    resources :workplace_counts, param: :workplace_count_id, except: :edit do
      post 'create_list', to: 'workplace_counts#create_list', on: :collection
    end
    # Рабочие места
    resources :workplaces, param: :workplace_id do
      collection do
        # Вывести все РМ списком
        get 'list_wp', to: 'workplaces#list_wp'
        # Подтвердить/отклонить конфигурацию РМ
        put 'confirm', to: 'workplaces#confirm'
        # Получить данные о системном блоке из аудита
        get 'pc_config_from_audit/:invent_num', to: 'workplaces#pc_config_from_audit', constraints: { invent_num: /.*/ }
        # Скачать скрипт для генерации файла конфигурации ПК
        get 'pc_script', to: 'workplaces#send_pc_script'
      end
    end

    # Запросы с ЛК
    # Проверка доступа к разделу "Вычислительная техника" в ЛК.
    get '***REMOVED***_invents/svt_access', to: '***REMOVED***_invents#svt_access'
    # Инициализация
    get '***REMOVED***_invents/init_properties', to: '***REMOVED***_invents#init_properties'
    # Получить данные по выбранном отделу (список РМ, макс. число, список работников отдела)
    get '***REMOVED***_invents/show_division_data/:division', to: '***REMOVED***_invents#show_division_data', constraints: { division: /\d+/ }
    # Получить данные о системном блоке из аудита
    get '***REMOVED***_invents/pc_config_from_audit/:invent_num',
        to: '***REMOVED***_invents#pc_config_from_audit',
        constraints: { invent_num: /.*/ }
    # Записать данные о РМ
    post '***REMOVED***_invents/create_workplace', to: '***REMOVED***_invents#create_workplace'
    # Получить данные о РМ
    get '***REMOVED***_invents/edit_workplace/:workplace_id',
        to: '***REMOVED***_invents#edit_workplace',
        constraints: { workplace_id: /\d+/ }
    # Обновить данные о РМ
    patch '***REMOVED***_invents/update_workplace/:workplace_id',
          to: '***REMOVED***_invents#update_workplace',
          constraints: { workplace_id: /\d+/ }
    # Удалить РМ
    delete '***REMOVED***_invents/destroy_workplace/:workplace_id',
           to: '***REMOVED***_invents#destroy_workplace',
           constraints: { workplace_id: /\d+/ }
    # Создать PDF файл со списком РМ для отдела
    get '***REMOVED***_invents/generate_pdf/:division', to: '***REMOVED***_invents#generate_pdf', constraints: { division: /\d+/ }
    # Скачать скрипт для генерации файла конфигурации ПК
    get '***REMOVED***_invents/pc_script', to: '***REMOVED***_invents#send_pc_script'
  end

  # Эталоны
  namespace :standart do

  end

  # Получить html-код кнопки "Добавить запись"
  get 'link/new_record', to: 'application#link_to_new_record'

  mount ActionCable.server, at: '/cable'
end
