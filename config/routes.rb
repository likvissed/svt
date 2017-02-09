Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root 'work_places#index'

  # Инвентаризация
  resources :workplaces, param: :workplace_id
  resources :count_workplaces, param: :count_workplace_id, except: :edit do
    get 'link/new_record', to: 'count_workplaces#link_to_new_record', on: :collection
  end

  # Эталоны
  resources :system_units
end
