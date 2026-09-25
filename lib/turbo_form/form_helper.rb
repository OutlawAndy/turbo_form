module TurboForm
  # Prepended onto ActionView::Helpers::FormHelper.
  #
  #   form_for @widget, dynamic: true
  module FormHelper
    # `form_for` ends in `form_with`, so overriding one covers both. `dynamic:`
    # stays in the options so the builder sees it; Rails slices the form tag's
    # attributes out by name, so it never reaches the HTML.
    def form_with(model: false, scope: nil, url: nil, format: nil, **options, &block)
      wire_dynamic_form(options) if options[:dynamic]
      super
    end

    private
      # `form_for` funnels HTML attributes through options[:html] while `form_with`
      # takes them at the top level. Write wherever the caller already is, and sit
      # alongside any Stimulus controller they asked for rather than replacing it.
      def wire_dynamic_form(options)
        attributes = options.key?(:html) ? (options[:html] ||= {}) : options
        data = attributes[:data] ||= {}

        data[:controller] = [ data[:controller], "turbo-form" ].compact.join(" ")
      end
  end
end
