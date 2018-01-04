Rails.application.routes.draw do
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  devise_for :users, controllers: { sessions: 'users/sessions',
                                    confirmations: 'users/confirmations',
                                    unlocks: 'users/unlocks',
                                    passwords: 'users/passwords' }

  authenticated do
    root to: "home#dashboard"
  end

  root to: "home#index"

  resources :properties
  resources :leads
  resources :lead_sources do
    post 'reset_token', on: :member
  end

  namespace :api do
    namespace :v1 do
      get 'docs/swagger.:format', to: "swagger#index"
      get 'docs', to: "swagger#apidocs"
      resources :leads
    end
  end

end
