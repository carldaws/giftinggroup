Rails.application.routes.draw do
  resource :session, only: %i[ new create destroy ]
  resource :registration, only: %i[ new create ]

  root "groups#index"

  get "up" => "rails/health#show", as: :rails_health_check # rubocop:disable Guardrails/RestfulRoutes
end
