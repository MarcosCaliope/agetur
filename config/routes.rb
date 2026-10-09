Rails.application.routes.draw do
  
  resources :companies
  resources :sorder_items do
    resources :recebimentos, controller: "sorder_item_payments", only: %i[index create destroy]
  end
  get 'showcomis', to: 'sorder_items#showcomis'
  resources :sorders do
    member do
      get 'export'
      patch 'encerrar'
      patch 'reabrir'
    end
  end

  resources :bookings, path: "agendamentos" do
    get 'pendentes', on: :collection
    resources :items, controller: "booking_items", path: "passeios", only: %i[create edit update destroy] do
      member do
        patch 'lancar'
        patch 'retirar'
      end
      resources :recebimentos, controller: "booking_item_payments", only: %i[index create destroy]
    end
  end
  resources :pickup_times, path: "horarios-de-passeio", except: :show

  resources :cash_entries, path: "caixa", except: :show
  resources :payables, path: "contas-a-pagar", except: :show do
    member do
      get 'pagamento'
      patch 'pagar'
      patch 'estornar'
    end
  end
  
  resources :agencies
  resources :hotels
  resources :vendors do
    resource :comissoes, only: %i[show update], controller: "vendor_destinations", path: "comissoes-por-roteiro"
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

  scope 'manutencao' do
    get 'sistger', to: 'sistger_imports#index', as: :sistger_imports
    post 'sistger', to: 'sistger_imports#create'
    get 'sistger/:etapa', to: 'sistger_imports#show', as: :sistger_import
  end

  get '/txt', to: 'txt#index'
  post '/txt/importar',  to: 'txt#importar'

  root to: 'site/welcome#index'

  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?
 
  resources :customers
  resources :states
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
