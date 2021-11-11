Rails.application.routes.draw do
  require 'sidekiq/web'

  devise_for :users

  devise_scope :user do
    get 'users/callbacks/registration_user', to: 'users/callbacks#registration_user'
    get 'users/callbacks/authorize_user', to: 'users/callbacks#authorize_user'

    root 'invent/workplaces#index'
  end

  authenticate :user, lambda { |u| u.role? :admin } do
    mount Sidekiq::Web => '/sidekiq'
  end

  resources :users

  # Инвентаризация
  namespace :invent do
    # Отделы
    resources :workplace_counts, param: :workplace_count_id do #, except: :edit
      collection do
        # Сформировать файл со списком РМ и их составом
        get 'generate_pdf/:division', to: 'workplace_counts#generate_pdf', constraints: { division: /\d+/ }
        # post 'create_list', to: 'workplace_counts#create_list'
      end
    end
    # Рабочие места
    resources :workplaces, except: [:update], param: :workplace_id do
      collection do
        # Вывести все РМ списком
        get 'list_wp', to: 'workplaces#list_wp'
        # Подтвердить/отклонить конфигурацию РМ
        put 'confirm', to: 'workplaces#confirm'
        # Скачать скрипт для генерации файла конфигурации ПК
        get 'pc_script', to: 'workplaces#send_pc_script'
        # Получить количество замороженных рабочих мест у данного отдела
        get 'count_freeze/:workplace_count_id', to: 'workplaces#count_freeze', constraints: { workplace_count_id: /\d+/ }
      end

      put 'update', as: 'update', on: :collection
      delete 'hard_destroy', to: 'workplaces#hard_destroy', on: :member
    end

    # Скачивание файлов, прикрепленных к рабочему месту
    # прямой путь используется в /services/invent/workplaces/list_wp.rb
    get 'attachments/download/:id', to: 'attachments#download', as: 'attachments/download'

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
    # Расшифровать файл конфигурации ПК, загруженный пользователем.
    post '***REMOVED***_invents/pc_config_from_user', to: '***REMOVED***_invents#pc_config_from_user'
    # Записать данные о РМ
    # post '***REMOVED***_invents/create_workplace', to: '***REMOVED***_invents#create_workplace'
    # Получить данные о РМ
    # get '***REMOVED***_invents/edit_workplace/:workplace_id', to: '***REMOVED***_invents#edit_workplace', constraints: { workplace_id: /\d+/ }
    # Обновить данные о РМ
    # patch '***REMOVED***_invents/update_workplace/:workplace_id', to: '***REMOVED***_invents#update_workplace', constraints: { workplace_id: /\d+/ }
    # Удалить РМ
    # delete '***REMOVED***_invents/destroy_workplace/:workplace_id', to: '***REMOVED***_invents#destroy_workplace', constraints: { workplace_id: /\d+/ }
    # Создать PDF файл со списком РМ для отдела
    get '***REMOVED***_invents/generate_pdf/:division', to: '***REMOVED***_invents#generate_pdf', constraints: { division: /\d+/ }
    # Скачать скрипт для генерации файла конфигурации ПК
    get '***REMOVED***_invents/pc_script', to: '***REMOVED***_invents#send_pc_script'
    # Проверить, существует ли техника с указанным инвентарным номером
    get '***REMOVED***_invents/existing_item', to: '***REMOVED***_invents#existing_item'
    # Показать данные по указанной технике
    get '***REMOVED***_invents/invent_item', to: '***REMOVED***_invents#invent_item'

    resources :items, except: [:new, :create], param: :item_id do
      collection do
        get 'avaliable/:type_id', to: 'items#avaliable', constraints: { type_id: /\d+/ }
        get 'busy', to: 'items#busy'
        # Получить данные о системном блоке из аудита
        get 'pc_config_from_audit/:invent_num', to: 'items#pc_config_from_audit', constraints: { invent_num: /.*/ }
        # Расшифровать файл конфигурации ПК, загруженный пользователем.
        post 'pc_config_from_user', to: 'items#pc_config_from_user'
        # Отправить технику на склад
        post 'to_stock', to: 'items#to_stock'
        # Списать технику
        post 'to_write_off', to: 'items#to_write_off'
        # Отметить как правильно переклеенный штрих-код
        get 'assign_invalid_barcode_as_true/:item_id', to: 'items#assign_invalid_barcode_as_true'
      end
    end

    resources :vendors, only: [:index, :create, :destroy], param: :vendor_id
    resources :models, param: :model_id
  end

  # Эталоны
  namespace :standard do

  end

  # Склад
  namespace :warehouse do
    # Получить информацию о всех расположениях
    get 'locations/load_locations', to: 'locations#load_locations'

    get 'locations/load_rooms/:building_id', to: 'locations#rooms_for_building'

    resources :items
    # Разделить одну технику на множество с разным расположением на складе
    put 'items/:id/split', to: 'items#split'
    
    resources :orders, only: [:new, :edit, :destroy] do
      get 'in', to: 'orders#index_in', on: :collection
      get 'out', to: 'orders#index_out', on: :collection
      get 'write_off', to: 'orders#index_write_off', on: :collection
      get 'archive', to: 'orders#archive', on: :collection
      get 'print', to: 'print', on: :member
      post 'create_in', to: 'orders#create_in', on: :collection
      post 'create_out', to: 'orders#create_out', on: :collection
      post 'create_write_off', to: 'orders#create_write_off', on: :collection
      post 'execute_in', to: 'orders#execute_in', on: :member
      post 'execute_out', to: 'orders#execute_out', on: :member
      post 'execute_write_off', to: 'orders#execute_write_off', on: :member
      post 'prepare_to_deliver', to: 'orders#prepare_to_deliver', on: :member
      put 'update_in', to: 'orders#update_in', on: :member
      put 'update_out', to: 'orders#update_out', on: :member
      put 'update_write_off', to: 'orders#update_write_off', on: :member
      put 'confirm', to: 'orders#confirm', on: :member
      put 'assign_op_receiver', to: 'orders#assign_operation_receiver', on: :member
    end
    # Добавление файла к исполненному расходному ордеру
    post 'attachment_orders', to: 'attachment_orders#create', as: 'attachment_orders'
    # Скачивание файла, прикрепленое к исполненному расходному ордеру
    get 'attachment_orders/download/:id', to: 'attachment_orders#download', as: 'attachment_orders/download'

    resources :supplies

    resources :requests, only: [:index, :edit] do
      put 'send_for_analysis', to: 'requests#send_for_analysis', on: :member
      put 'confirm_request_and_order', to: 'requests#confirm_request_and_order', on: :member
      put 'assign_new_executor', to: 'requests#assign_new_executor', on: :member

      get 'close', to: 'requests#close', on: :member
    end

    get 'attachment_requests/download/:id', to: 'attachment_requests#download', as: 'attachment_requests/download'
  end

  # Получить html-код кнопки "Добавить запись"
  get 'link/new_record', to: 'application#link_to_new_record'

  resources :user_isses, only: :index do
    # Получить список пользователей указанного отдела
    get 'users_from_division/:division', to: 'user_isses#users_from_division', on: :collection
    # Получить список техники привязанной за пользователем
    get :items, to: :items
  end

  resource :statistics, only: :show
  get 'statistics/export', to: 'statistics#export', as: 'statistics/export'

  namespace :api do
    namespace :v1 do
      namespace :invent do
        resources :items, only: :index 
      end
      # Очистить кэш во всём приложении
      get 'clear_cache_app', to: 'cache#clear'
    end

    namespace :v2 do
      namespace :invent do
        resources :items, only: :index

        # Поиска техники по штрих-коду, возвращает объект
        get 'items/:barcode', to: 'items#barcode'
         # Поиска техники по filtering_params, возвращает массив
        get 'search_items', to: 'items#search_items'
      end
    end

    namespace :v3 do
      namespace :warehouse do
        # Добавление новой заявки категории 1
        post 'requests/new_office_equipment', to: 'requests#new_office_equipment'
        # Ответ от пользователя (подтверждение/отклонение обработанной заявки)
        post 'requests/answer_from_user/:id', to: 'requests#answer_from_user'
      end
    end
  end

  mount ActionCable.server, at: '/cable'
end
