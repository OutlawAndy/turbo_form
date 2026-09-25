module TurboForm
  # A callable route concern. Draws a PATCH beside a resource's `new` and `edit`,
  # at the same paths, onto the one shadow action that renders them from what
  # the form currently holds.
  #
  #   concern :dynamic_form, TurboForm::Routes
  #   resources :widgets, concerns: :dynamic_form
  module Routes
    def self.call(mapper, _options = {})
      mapper.patch :new, on: :collection, path: "new", action: :dynamic_form, as: nil, defaults: { turbo_form: "new" }
      mapper.patch :edit, on: :member, action: :dynamic_form, as: nil, defaults: { turbo_form: "edit" }
    end
  end
end
