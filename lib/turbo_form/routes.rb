module TurboForm
  # A callable route concern. Draws a PATCH beside whichever of a resource's `new`
  # and `edit` it has, at the same paths and onto the same actions, marked so the
  # controller renders them from what the form currently holds.
  #
  #   resources :widgets, concerns: :turbo_form
  module Routes
    def self.call(mapper, _options = {})
      actions = mapper.send(:parent_resource).actions

      mapper.new { mapper.patch :new, as: nil, defaults: { dynamic_form: true } } if actions.include?(:new)
      mapper.patch :edit, on: :member, as: nil, defaults: { dynamic_form: true } if actions.include?(:edit)
    end

    # Rails keeps concerns per Mapper, and builds a fresh one for every `draw`,
    # `prepend` and `append`, so declaring it once from the engine can't reach
    # them all. An app's own `concern :turbo_form` still replaces this one.
    module Declared
      def initialize(...)
        super
        concern :turbo_form, TurboForm::Routes
      end
    end
  end
end
