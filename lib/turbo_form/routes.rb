module TurboForm
  # A callable route concern. Draws a PATCH beside whichever of a resource's `new`
  # and `edit` it has, at the same paths and onto the same actions, marked so the
  # controller renders them from what the form currently holds.
  #
  #   concern :turbo_form, TurboForm::Routes
  #   resources :widgets, concerns: :turbo_form
  module Routes
    def self.call(mapper, _options = {})
      actions = mapper.send(:parent_resource).actions

      mapper.new { mapper.patch :new, as: nil, defaults: { dynamic_form: true } } if actions.include?(:new)
      mapper.patch :edit, on: :member, as: nil, defaults: { dynamic_form: true } if actions.include?(:edit)
    end
  end
end
