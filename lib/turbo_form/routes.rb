module TurboForm
  # A callable route concern. Draws a PATCH beside a resource's `new` and `edit`,
  # at the same paths, onto the one shadow action that renders them from what
  # the form currently holds.
  #
  #   concern :turbo_form, TurboForm::Routes
  #   resources :widgets, concerns: :turbo_form
  module Routes
    def self.call(mapper, _options = {})
      mapper.patch :new, on: :collection, path: 'new', action: :dynamic_form, as: nil, defaults: { dynamic_action: 'new' }
      mapper.patch :edit, on: :member, action: :dynamic_form, as: nil, defaults: { dynamic_action: 'edit' }
    end
  end
end
