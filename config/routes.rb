Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root 'workplaces#index'

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

  # Эталоны
  resources :system_units
end
