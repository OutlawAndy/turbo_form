Rails.application.routes.draw do
  resources :widgets, only: %i[new create], concerns: :turbo_form do
    patch :summary, on: :collection
  end

  resources :orders, only: :new, concerns: :turbo_form

  get 'up' => 'rails/health#show', as: :rails_health_check
end
