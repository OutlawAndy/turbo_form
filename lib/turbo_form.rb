require "active_support/core_ext/module/attribute_accessors"
require "turbo_form/version"
require "turbo_form/engine"

module TurboForm
  # The controller the engine's endpoint inherits from. Defaulting to the host's
  # own `ApplicationController` means its `before_action`s -- authentication
  # above all -- apply to dynamic renders for free. Point it elsewhere when that
  # inheritance brings something the endpoint shouldn't have.
  mattr_accessor :parent_controller, default: "ApplicationController"

  # Set to false to keep the engine out of the host's route set and draw its
  # route yourself.
  mattr_accessor :draw_routes, default: true

  # Run as the body of a `before_action`, inside the endpoint, and handed the
  # resource the form was rebuilt into. The endpoint is an inherited controller
  # the host never wrote, so this is where it gets to treat it like one of its
  # own: authorize the render, skip a filter the endpoint can't satisfy
  # (`skip_authorization`), set something the template needs. Left alone, only
  # the host's own inherited filters apply.
  mattr_accessor :before_render

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
