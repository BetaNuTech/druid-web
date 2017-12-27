Rails.application.routes.draw do
  resources :properties
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  namespace :api do
    namespace :v1 do
      get 'docs/swagger.:format', to: "swagger#index"
      get 'docs', to: "swagger#apidocs"
      resources :leads
    end
  end

  resources :leads
  resources :lead_sources do
    post 'reset_token', on: :member
  end

  root to: "home#index"
end
