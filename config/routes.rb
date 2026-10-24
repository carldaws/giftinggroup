Rails.application.routes.draw do
  constraints(host: "www.giftinglists.com") do
    get "(*path)", to: redirect(host: "giftinglists.com"), format: false # rubocop:disable Guardrails/RestfulRoutes
  end

  resource :session, only: %i[ new create destroy ]
  resource :registration, only: %i[ new create ]
  resource :account_deletion, only: %i[ new create ]
  resource :privacy, only: :show, controller: :privacy
  resources :passwords, only: %i[ edit update ], param: :token

  resources :groups, only: %i[ index new create show edit update ] do
    scope module: :groups do
      resources :memberships, only: %i[ create update destroy ] do
        scope module: :memberships do
          resource :sign_in_link, only: :show
          resources :messages, only: %i[ index create ]
        end
      end
      resources :dependants, only: %i[ new create ]
      resources :occasions, only: %i[ new create edit update destroy ]
      resource :holidays, only: %i[ edit update ]
      resource :join_code, only: :update
    end
  end

  resources :people, only: :show do
    scope module: :people do
      resource :profile, only: %i[ edit update ]
      resources :items, only: %i[ new create ]
      resources :interests, only: %i[ create destroy ]
      resources :sizes, only: %i[ create destroy ]
    end
  end

  resources :items, only: %i[ edit update destroy ] do
    scope module: :items do
      resource :reservation, only: %i[ create update destroy ]
      resource :purchase, only: %i[ create destroy ]
      resource :receipt, only: %i[ create destroy ]
      resources :photos, only: :destroy
    end
  end

  resources :joins, path: "join", only: %i[ new create show ], param: :join_code

  constraints(->(request) { Session.exists?(id: request.cookie_jar.signed[:session_id]) }) do
    root "groups#index", as: :signed_in_root
  end
  root "home#show"

  get "up" => "rails/health#show", as: :rails_health_check # rubocop:disable Guardrails/RestfulRoutes
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest # rubocop:disable Guardrails/RestfulRoutes
end
