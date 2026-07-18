Rails.application.routes.draw do
  
  resources :service_order_items
  resources :agencies
  resources :hotels
  resources :vendors
  resources :service_orders
  
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
  
  root to: 'site/welcome#index'
 
  resources :customers
  resources :states
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
