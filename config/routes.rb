Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      get "dashboard", to: "dashboard#show"

      namespace :admin do
        get "dashboard", to: "dashboard#show"
      end

      post "auth/login", to: "auth#login"
      post "auth/register", to: "auth#register"
      get "auth/me", to: "auth#me"
      resources :contact_requests, only: [:create]
      resources :plans, only: [:index]

      resources :customers
      resources :sites
      resources :service_categories
      resources :service_items
      resources :quotes
      resources :quote_items

      resources :teams do
        get :available_members,
            on: :member,
            controller: "team_members"

        resources :members,
                  controller: "team_members",
                  only: %i[index create update destroy]
      end

      resources :team_memberships
      resources :vehicles
      resources :equipment
      resources :jobs
      resources :job_assignments
      resources :job_time_entries
      resources :job_reports do
        get :pdf, on: :member
      end

      resources :invoices do
        get :pdf, on: :member
      end
      resources :invoice_items
    end
  end
end