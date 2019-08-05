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

    collection do
      delete :failed, controller: :tasks, action: :clear_failed
      get :healthcheck, controller: :tasks_healthcheck, action: :index
    end
  end

  resources :nodes, only: [:index, :create, :update, :destroy], param: :uuid do
    member do
      post :accept_new_tasks, :reject_new_tasks, :kill_containers
    end

    collection do
      get :healthcheck, controller: :nodes_healthcheck, action: :index
    end
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root to: "status#index"

  get "/healthcheck" => "healthcheck#index"

  require "sidekiq/pro/web"
  require 'sidekiq-scheduler/web'
  mount Sidekiq::Web => '/jobs'
end
