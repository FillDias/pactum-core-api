Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"

      post "auth/register", to: "auth#register"
      post "auth/login",    to: "auth#login"
      post "auth/sync",     to: "auth#sync"
      delete "auth/logout", to: "auth#logout"

      resources :portfolios do
        resources :transactions, only: [:index, :create, :destroy]
        resources :positions,    only: [:index]
        post "calculations/nav", to: "calculations#nav"
        post "calculations/cdi", to: "calculations#cdi"
        post "calculations/twr", to: "calculations#twr"
        post "calculations/irr", to: "calculations#irr"
      end

      resources :securities, only: [:index, :create, :update] do
        collection do
          get :search
          get :brapi_lookup
        end
      end
    end
  end
end
