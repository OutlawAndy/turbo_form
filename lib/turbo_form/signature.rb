module TurboForm
  # A tamper-proof description of a dynamic form, carried in the URL the browser
  # posts back to.
  #
  # It is signed because the endpoint acts on every word of it: `model_name` gets
  # constantized and instantiated, `template` gets rendered. Neither may come
  # from the client unverified.
  #
  # Note that this identifies a *class*, not a record. Dynamic forms are usually
  # editing something unsaved, which is also why GlobalID -- which requires a
  # persisted record -- can't express it.
  class Signature
    class Invalid < StandardError; end

    def self.verify(token)
      payload = TurboForm.verifier.verified(token.to_s)
      raise Invalid, "not a signature this application generated" unless payload

      new(**payload.symbolize_keys)
    end

    attr_reader :model_name, :scope, :template

    def initialize(model_name:, scope:, template: nil)
      @model_name = model_name
      @scope = scope
      @template = template
    end

    def model = model_name.constantize

    # By convention the template sits alongside the resource's own partial:
    # `widgets/_widget` gets `widgets/dynamic_form`.
    def template_for(resource)
      template || File.join(File.dirname(resource.to_partial_path), "dynamic_form")
    end

    def to_s
      TurboForm.verifier.generate({ model_name:, scope:, template: })
    end
    alias to_param to_s
  end
end
