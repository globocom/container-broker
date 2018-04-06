Rails.application.routes.draw do
  resources :jobs, only: [:create, :show]

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  post "/handshake", controller: "handshake", action: "create"

end
