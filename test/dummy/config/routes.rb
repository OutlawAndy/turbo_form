Rails.application.routes.draw do
  concern :dynamic_form, TurboForm::Routes

  resources :widgets, only: %i[new create], concerns: :dynamic_form

  get "up" => "rails/health#show", as: :rails_health_check
end
