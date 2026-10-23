Rails.application.routes.draw do
  resource :session, only: %i[ new create destroy ] do
    resource :verification, only: %i[ new create ], module: :sessions
  end
  resources :magic_links, only: :show, param: :token do
    resource :redemption, only: :create, module: :magic_links
  end
  resource :registration, only: %i[ new create ]

  root "groups#index"

  get "up" => "rails/health#show", as: :rails_health_check # rubocop:disable Guardrails/RestfulRoutes

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
