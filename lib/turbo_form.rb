require "turbo_form/version"
require "turbo_form/engine"

module TurboForm
  class << self
    attr_writer :verifier

    # Signs the description of a form so the endpoint can trust the class it is
    # about to instantiate and the template it is about to render. Derived from
    # the application's own key generator, the way SignedGlobalID is. `url_safe`
    # so the token can live in a path segment; JSON so nothing Marshalled ever
    # crosses the wire.
    def verifier
      @verifier ||= ActiveSupport::MessageVerifier.new(
        Rails.application.key_generator.generate_key("turbo_form"),
        url_safe: true, serializer: JSON
      )
    end
  end
end
