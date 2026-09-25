module TurboForm
  # Prepended onto ActionView::Helpers::FormHelper.
  #
  #   form_for @widget, dynamic: true
  module FormHelper
    # `form_for` ends in `form_with`, so overriding one covers both. `dynamic:`
    # stays in the options so the builder sees it; Rails slices the form tag's
    # attributes out by name, so it never reaches the HTML.
    def form_with(model: false, scope: nil, url: nil, format: nil, **options, &block)
      wire_dynamic_form(options, model) if options[:dynamic]
      super
    end

    private
      # `form_for` funnels HTML attributes through options[:html] while `form_with`
      # takes them at the top level. Write wherever the caller already is.
      def wire_dynamic_form(options, model)
        attributes = options.key?(:html) ? (options[:html] ||= {}) : options
        (attributes[:data] ||= {})[:turbo_form_url] = namesake_path(model)
      end

      # The page the form is on, which TurboForm::Routes answers PATCH on too.
      def namesake_path(model)
        polymorphic_path(model, action: Array(model).last.persisted? ? :edit : :new)
      end
  end
end
