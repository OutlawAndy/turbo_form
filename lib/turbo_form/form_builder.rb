module TurboForm
  # Prepended onto ActionView::Helpers::FormBuilder.
  #
  #   f.text_field :name, dynamic_trigger: true      # re-render on the default event
  #   f.select :category, categories, {}, dynamic_trigger: :blur
  #
  # `dynamic_trigger:` always has to end up as a data attribute, but where it
  # *arrives* depends on the helper. Most treat their `options` hash as the tag's
  # HTML attributes; the select and date families keep those in a trailing
  # `html_options` instead, which is where these overrides earn their keep.
  module FormBuilder
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
        return [ options, absorb_trigger(html_options) ] unless options.key?(:dynamic_trigger)

        trigger = options[:dynamic_trigger]
        [ options.except(:dynamic_trigger), absorb_trigger(html_options.merge(dynamic_trigger: trigger)) ]
      end

      def absorb_trigger(attributes)
        return attributes unless attributes.key?(:dynamic_trigger)

        trigger = attributes[:dynamic_trigger]
        attributes = attributes.except(:dynamic_trigger)
        return attributes unless trigger

        attributes.merge(data: { **attributes[:data].to_h, turbo_form_trigger: trigger_event(trigger) })
      end

      # Left blank for `true`, which the script reads as the element's own
      # default: `change` for a select, `input` for a text field, `click` for a
      # button.
      def trigger_event(trigger) = trigger == true ? "" : trigger.to_s
  end
end
