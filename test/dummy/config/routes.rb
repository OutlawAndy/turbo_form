Rails.application.routes.draw do
  concern :turbo_form, TurboForm::Routes

  resources :widgets, only: %i[new create], concerns: :turbo_form

  get "up" => "rails/health#show", as: :rails_health_check
end
