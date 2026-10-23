Rails.application.routes.draw do
  # Render's health check (render.yaml); public, outside the app's login.
  get 'up', to: 'rails/health#show', as: :rails_health_check
  
  resources :companies
  resources :sorder_items do
    patch 'reativar', on: :member
    resources :recebimentos, controller: "sorder_item_payments", only: %i[index create destroy]
  end
  get 'showcomis', to: 'sorder_items#showcomis'
  get 'relatorios/ordens', to: 'relacao_ordens#index', as: :relacao_ordens
  get 'relatorios/resumo-operacional', to: 'resumo_operacional#index', as: :resumo_operacional
  get 'relatorios/passeios-repassados', to: 'passeios_repassados#index', as: :passeios_repassados
  get 'relatorios/agendamentos-por-usuario', to: 'agendamentos_por_usuario#index', as: :agendamentos_por_usuario
  get 'comissoes/pagamento', to: 'commission_payments#index', as: :pagamento_comissoes
  post 'comissoes/pagamento', to: 'commission_payments#create'
  resources :sorders do
    member do
      get 'export'
      get 'historico'
      patch 'encerrar'
      patch 'reabrir'
      match 'editando', via: %i[patch delete]
    end
  end

  # Before bookings, whose /agendamentos/:id would take "sinais-a-conferir".
  get 'agendamentos/sinais-a-conferir', to: 'conferencia_sinais#index', as: :conferencia_sinais
  patch 'agendamentos/sinais-a-conferir/:id/confirmar', to: 'conferencia_sinais#confirmar', as: :confirmar_sinal
  patch 'agendamentos/sinais-a-conferir/:id/recusar', to: 'conferencia_sinais#recusar', as: :recusar_sinal
  resources :vendas, only: %i[index new create show] do
    post :pagamento, on: :member
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

  resources :cash_entries, path: "caixa", except: :show do
    get 'recibo', on: :member
  end
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
    resources :users, path: "usuarios", except: :show
  end
  
  devise_for :users
  devise_for :admins
 
  get 'inicio', to: 'site/welcome#index'
  patch 'trocar-empresa', to: 'troca_empresa#update', as: :trocar_empresa
  get 'minha-senha', to: 'senhas#edit', as: :minha_senha
  patch 'minha-senha', to: 'senhas#update'

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
