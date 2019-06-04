Rails.application.routes.draw do
  resources :status, only: :index do
    collection do
      get :nodes
      get :tasks
      get :tags
      get :tag_values
      get :task_statuses
      post "retry_task/:uuid", action: :retry_task
    end
  end

  resources :tasks, only: [:create, :show], param: :uuid do
    get :logs, on: :member
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  post "/handshake", controller: "handshake", action: "create"

  root to: "status#index"

  get "/healthcheck" => "healthcheck#index"

  require "sidekiq/pro/web"
  require 'sidekiq-scheduler/web'
  mount Sidekiq::Web => '/jobs'
end
