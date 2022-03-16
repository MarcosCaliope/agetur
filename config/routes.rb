Rails.application.routes.draw do
  
  resources :companies
  resources :sorder_items do
    # get '/sorder_items_export' => 'sorder_items#export'
    # get 'showcomis', to: 'sorder_items#showcomis'
   # get 'conta/meu_perfil'
  end

  get 'showcomis', to: 'sorder_items#showcomis'

  resources :sorders do
    get 'export'
    
  end
  
  resources :agencies
  resources :hotels
  resources :vendors
  
  resources :service_orders  do  #, :has_many => :service_order_items
    end
  
  resources :vehicles
  resources :drivers
  resources :tourguides
  resources :destinations
  
  namespace :site do
    get 'welcome/index'
  end
  namespace :users_backoffice do
    get 'welcome/index'
  end
  namespace :admins_backoffice do
    get 'welcome/index'
  end
  
  devise_for :users
  devise_for :admins
 
  get 'inicio', to: 'site/welcome#index'

  get '/txt', to: 'txt#index'
  post '/txt/importar',  to: 'txt#importar'

  root to: 'site/welcome#index'
 
  resources :customers
  resources :states
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
