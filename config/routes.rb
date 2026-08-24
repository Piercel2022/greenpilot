Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  namespace :api do
  namespace :v1 do
    post "auth/login", to: "auth#login"
    get "auth/me", to: "auth#me"

    resources :customers
    resources :sites
    resources :service_categories
    resources :service_items
    resources :quotes
    resources :quote_items
    resources :teams
    resources :team_memberships
    resources :vehicles
    resources :equipment
    resources :jobs
    resources :job_assignments
    resources :job_time_entries
    resources :job_reports
    resources :invoices
    resources :invoice_items
  end
 end
end
