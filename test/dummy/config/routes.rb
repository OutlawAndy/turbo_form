Rails.application.routes.draw do
  resources :widgets, only: %i[new create]

  get "up" => "rails/health#show", as: :rails_health_check
end
