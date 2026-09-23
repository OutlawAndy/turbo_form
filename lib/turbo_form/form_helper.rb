module TurboForm
  # Prepended onto ActionView::Helpers::FormHelper.
  #
  #   form_for @widget, dynamic: true
  #   form_for @widget, dynamic: "shared/refresh"   # render this template instead
  module FormHelper
    # `form_for` ends in `form_with`, so overriding one covers both.
    def form_with(model: false, scope: nil, url: nil, format: nil, **options, &block)
      dynamic = options.delete(:dynamic)
      return super unless dynamic

      object = _object_for_form_builder(model)
      raise ArgumentError, "form_for/form_with needs a :model to build a dynamic form from" unless object

      scope ||= model_name_from_record_or_class(object).param_key
      signature = TurboForm::Signature.new(
        model_name: object.class.name,
        scope: scope.to_s,
        template: (dynamic unless dynamic == true),
        **origin_of(object)
      )

      wire_dynamic_form(options, signature)
      super(model:, scope:, url:, format:, **options, &block)
    end

    private
      # A saved record is found again by id. An unsaved one is rebuilt from what
      # it had already been given -- a parent's foreign key, say -- since the
      # form may not submit that back. A plain form object with no dirty
      # tracking has nothing to carry.
      def origin_of(object)
        return { id: object.id } if object.try(:persisted?)

        { seed: object.try(:changes).to_h.transform_values(&:last) }
      end

      # `form_for` funnels HTML attributes through options[:html] while `form_with`
      # takes them at the top level. Write wherever the caller already is, and sit
      # alongside any Stimulus controller they asked for rather than replacing it.
      def wire_dynamic_form(options, signature)
        attributes = options.key?(:html) ? (options[:html] ||= {}) : options
        data = attributes[:data] ||= {}

        data[:controller] = [ data[:controller], "turbo-form" ].compact.join(" ")
        data[:turbo_form_url_value] = turbo_form_path(signature)
      end
  end
end
