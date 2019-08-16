# frozen_string_literal: true

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

    member do
      put :mark_as_error
    end

    collection do
      delete :errors, action: :clear_errors
      get :healthcheck, controller: :tasks_healthcheck, action: :index
    end
  end

  resources :nodes, except: %i[edit new], param: :uuid do
    member do
      post :accept_new_tasks, :reject_new_tasks, :kill_containers
    end

    collection do
      get :healthcheck, controller: :nodes_healthcheck, action: :index
    end
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root to: redirect(Settings.backstage_admin.url)

  get "/healthcheck" => "healthcheck#index"

  require "sidekiq/pro/web"
  require 'sidekiq-scheduler/web'
  mount Sidekiq::Web => '/jobs'
end
