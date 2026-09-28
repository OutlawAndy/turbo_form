module TurboForm
  # Prepended onto ActionView::Helpers::Tags::SelectRenderer, which every select
  # tag renders through -- including those of builder methods other gems add,
  # like country_select's, which hand their html_options straight to the tag.
  module SelectRenderer
    private
    def select_content_tag(option_tags, options, html_options)
      super(option_tags, options, FormBuilder.absorb_trigger(html_options.symbolize_keys, @template_object))
    end
  end
end
