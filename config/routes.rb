Rails.application.routes.draw do
  resources :roles
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  devise_for :users, controllers: { sessions: 'users/sessions',
                                    confirmations: 'users/confirmations',
                                    unlocks: 'users/unlocks',
                                    passwords: 'users/passwords' }

  authenticated do
    root to: "home#dashboard", as: :authenticated_root
  end
  root to: redirect('/users/sign_in')
  #root to: "home#index"

  resources :users
  resources :properties
  resources :leads do
    member do
      post 'trigger_state_event', to: "leads#trigger_state_event"
    end
  end
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
