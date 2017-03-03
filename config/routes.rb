Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/callbacks' }

  authenticated :user do
    root 'workplaces#index', as: :authenticated_root
  end

  devise_scope :user do
    root 'devise/sessions#new'
  end

  # Инвентаризация
  resources :workplaces, param: :workplace_id

  # Отделы
  resources :workplace_counts, param: :workplace_count_id, except: :edit do
    get 'link/new_record',    to: 'workplace_counts#link_to_new_record',  on: :collection
  end

  # Запросы с ЛК
  # Инициализация
  get '***REMOVED***_invents/init/:tn', to: '***REMOVED***_invents#init', constraints: { tn: /\d+/ }
  # Получить данные по выбранном отделу (список РМ, макс. число, список работников отдела)
  get '***REMOVED***_invents/show_division_data/:division', to: '***REMOVED***_invents#show_division_data', constraints: { division: /\d+/ }
  # Записать данные о РМ
  post '***REMOVED***_invents/create_workplace', to: '***REMOVED***_invents#create_workplace'

  # Эталоны
  resources :system_units
end
