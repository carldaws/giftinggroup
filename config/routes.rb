Rails.application.routes.draw do
  resource :session, only: %i[ new create destroy ]
  resource :registration, only: %i[ new create ]
  resources :passwords, only: %i[ edit update ], param: :token

  resources :groups, only: %i[ index new create show edit update ] do
    scope module: :groups do
      resources :memberships, only: %i[ update destroy ] do
        resource :sign_in_link, only: :show, module: :memberships
      end
      resources :dependants, only: %i[ new create ]
      resource :join_code, only: :update
    end
  end

  resources :joins, path: "join", only: %i[ new create show ], param: :join_code

  root "groups#index"

  get "up" => "rails/health#show", as: :rails_health_check # rubocop:disable Guardrails/RestfulRoutes
end
