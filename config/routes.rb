Rails.application.routes.draw do
  resources :status, only: :index

  resources :tasks, only: [:create, :show] do
    get :error_log, on: :member
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  post "/handshake", controller: "handshake", action: "create"


  root to: "status#index"

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
end
