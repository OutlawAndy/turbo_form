module TurboForm
  # Prepended onto ActionView::Helpers::FormBuilder.
  #
  #   f.text_field :name, dynamic_trigger: true      # re-render on the default event
  #   f.select :category, categories, {}, dynamic_trigger: :blur
  #   f.select :flavor, flavors, {}, dynamic_action: summary_widgets_path  # stream from a URL of its own
  #
  # `dynamic_trigger:` always has to end up as a data attribute, but where it
  # *arrives* depends on the helper. Most treat their `options` hash as the tag's
  # HTML attributes; the select and date families keep those in a trailing
  # `html_options` instead, which is where these overrides earn their keep.
  module FormBuilder
    DYNAMIC_OPTIONS = %i[dynamic_trigger dynamic_action].freeze

    def select(method, choices = nil, options = {}, html_options = {}, &block)
      super(method, choices, *hoist_trigger(options, html_options), &block)
    end

    def collection_select(method, collection, value_method, text_method, options = {}, html_options = {})
      super(method, collection, value_method, text_method, *hoist_trigger(options, html_options))
    end

    def grouped_collection_select(method, collection, group_method, group_label_method, option_key_method, option_value_method, options = {}, html_options = {})
      super(method, collection, group_method, group_label_method, option_key_method, option_value_method, *hoist_trigger(options, html_options))
    end

    def collection_checkboxes(method, collection, value_method, text_method, options = {}, html_options = {}, &block)
      super(method, collection, value_method, text_method, *hoist_trigger(options, html_options), &block)
    end

    def collection_radio_buttons(method, collection, value_method, text_method, options = {}, html_options = {}, &block)
      super(method, collection, value_method, text_method, *hoist_trigger(options, html_options), &block)
    end

    def time_zone_select(method, priority_zones = nil, options = {}, html_options = {})
      super(method, priority_zones, *hoist_trigger(options, html_options))
    end

    def weekday_select(method, options = {}, html_options = {})
      super(method, *hoist_trigger(options, html_options))
    end

    def date_select(method, options = {}, html_options = {})
      super(method, *hoist_trigger(options, html_options))
    end

    def time_select(method, options = {}, html_options = {})
      super(method, *hoist_trigger(options, html_options))
    end

    def datetime_select(method, options = {}, html_options = {})
      super(method, *hoist_trigger(options, html_options))
    end

    # These two hand their options straight to the tag helper, skipping
    # `objectify_options`, and take them first when no value is given.
    def submit(value = nil, options = {})
      value.is_a?(Hash) ? super(absorb_trigger(value)) : super(value, absorb_trigger(options))
    end

    def button(value = nil, options = {}, &block)
      value.is_a?(Hash) ? super(absorb_trigger(value), &block) : super(value, absorb_trigger(options), &block)
    end

    private
    # Every other field helper -- generated and hand-written alike -- passes its
    # attributes through here on the way to the tag.
    def objectify_options(options)
      super(absorb_trigger(options))
    end

    # A trailing `dynamic_trigger:` binds to `options` because Ruby folds bare
    # keywords into the first optional positional hash -- but for these helpers
    # that hash is the *select's* options, not the tag's. Carry it across.
    # SimpleForm arrives on the other side, via `input_html:`, so take it from
    # either.
    def hoist_trigger(options, html_options)
      [ options.except(*DYNAMIC_OPTIONS), absorb_trigger(html_options.merge(options.slice(*DYNAMIC_OPTIONS))) ]
    end

    # `dynamic_action:` makes a trigger of its own, on the default event unless
    # `dynamic_trigger:` names one. It takes whatever `url_for` does.
    def absorb_trigger(attributes)
      return attributes unless attributes.keys.intersect?(DYNAMIC_OPTIONS)

      trigger, action = attributes.values_at(*DYNAMIC_OPTIONS)
      attributes = attributes.except(*DYNAMIC_OPTIONS)
      trigger ||= action.present?
      return attributes unless trigger

      attributes.merge(data: { **attributes[:data].to_h, turbo_form_trigger: trigger_event(trigger), turbo_form_action: (@template.url_for(action) if action) })
    end

    # Left blank for `true`, which the script reads as the element's own
    # default: `change` for a select, `input` for a text field, `click` for a
    # button.
    def trigger_event(trigger) = trigger == true ? '' : trigger.to_s
  end
end
